import 'dart:io';

import 'package:artisan_args/artisan_args.dart';
import 'package:orm_playground/orm_playground.dart';
import 'package:orm_playground/src/database/seeders.dart' as playground_seeders;
import 'package:ormed/ormed.dart';

/// Shared CLI IO for styled output.
final io = ArtisanIO(
  style: ArtisanStyle(ansi: stdout.supportsAnsiEscapes),
  out: stdout.writeln,
  err: stderr.writeln,
);

Future<void> main(List<String> arguments) async {
  final logSql =
      arguments.contains('--sql') ||
      Platform.environment['PLAYGROUND_LOG_SQL'] == 'true';
  final seedOverrides = _extractSeedArguments(arguments);

  io.title('ORM Playground');

  // Create the playground database helper
  final database = PlaygroundDatabase();

  // Get the DataSource for the default tenant
  final ds = await database.dataSource();

  try {
    // Check if schema is ready
    if (!await _schemaReady(ds)) {
      io.error('Schema not ready!');
      io.note(
        'Run the ORM CLI to apply migrations:\n'
        '  dart run packages/orm/ormed_cli/bin/orm.dart migrate '
        '--config orm_playground/orm.yaml',
      );
      return;
    }

    // Seed the database
    io.info('Seeding database...');
    await playground_seeders.seedPlayground(
      ds.connection,
      names: seedOverrides.isEmpty ? null : seedOverrides,
    );
    io.success('Database ready.');

    // Enable SQL logging if requested
    if (logSql) {
      ds.beforeExecuting((statement) {
        io.writeln(io.style.muted('[SQL] ${statement.sqlWithBindings}'));
      });
    }

    // Run the showcases
    await _printPostSummaries(ds);
    await _runQueryBuilderShowcase(ds);
    await _runTableHelpers(ds);
    await _runPretendPreview(ds);
    await _runModelCrudShowcase(ds);
    await _runRelationQueryShowcase(ds);
    await _runPaginationShowcase(ds);
    await _runChunkingShowcase(ds);
    await _runTransactionShowcase(ds);

    io.newLine();
    io.success('All showcases completed successfully!');
  } finally {
    await database.dispose();
  }
}

List<String> _extractSeedArguments(List<String> args) {
  final seeds = <String>[];
  for (var i = 0; i < args.length; i++) {
    final arg = args[i];
    if (arg == '--seed') {
      if (i + 1 < args.length) {
        seeds.addAll(
          args[i + 1]
              .split(',')
              .map((value) => value.trim())
              .where((value) => value.isNotEmpty),
        );
        i++;
      }
    } else if (arg.startsWith('--seed=')) {
      final value = arg.substring('--seed='.length);
      seeds.addAll(
        value
            .split(',')
            .map((entry) => entry.trim())
            .where((entry) => entry.isNotEmpty),
      );
    }
  }
  return seeds;
}

Future<bool> _schemaReady(DataSource ds) async {
  final driver = ds.connection.driver;
  if (driver is! SchemaDriver) {
    io.error('Playground driver does not support schema inspection.');
    return false;
  }
  final schemaDriver = driver as SchemaDriver;
  final inspector = SchemaInspector(schemaDriver);
  final hasUsers = await inspector.hasTable('users');
  final hasPosts = await inspector.hasTable('posts');
  return hasUsers && hasPosts;
}

Future<void> _printPostSummaries(DataSource ds) async {
  final query = ds
      .query<Post>()
      .withRelation('author')
      .withRelation('tags')
      .withRelation('comments')
      .withCount('comments', alias: 'comments_count')
      .orderBy('published_at', descending: true);
  final rows = await query.rows();

  io.newLine();
  io.section('Latest Posts');

  if (rows.isEmpty) {
    io.warning('No posts found. Create one via the ORM CLI to continue.');
    return;
  }

  for (final row in rows) {
    final post = row.model;
    final tagList = post.tags.map((tag) => tag.name).join(', ');
    final commentCount =
        (row.row['comments_count'] as int?) ??
        row.relationList<Comment>('comments').length;
    io.writeln(
      '${io.style.success('•')} ${io.style.emphasize(post.title)} '
      'by ${post.author?.name ?? 'Unknown'} '
      '${io.style.muted('($commentCount comments, tags: ${tagList.isEmpty ? 'none' : tagList})')}',
    );
  }

  final preview = query.toSql();
  io.twoColumnDetail('Preview SQL', preview.sqlWithBindings);
}

Future<void> _runQueryBuilderShowcase(DataSource ds) async {
  io.newLine();
  io.section('Query Builder Helpers');

  // Using query<T>() from DataSource
  final rows = await ds
      .query<Post>()
      .withCount('comments', alias: 'comments_count')
      .orderBy('published_at', descending: true)
      .limit(3)
      .get();
  io.twoColumnDetail('Published posts with comment counts', '${rows.length}');

  // Using table() for ad-hoc queries
  final activeUserIds = await ds
      .table('users')
      .whereEquals('active', true)
      .pluck<int>('id');
  io.twoColumnDetail('Active user IDs', activeUserIds.join(', '));

  final latestComment = await ds
      .query<Comment>()
      .orderBy('created_at', descending: true)
      .firstOrNull();
  io.twoColumnDetail('Most recent comment', latestComment?.body ?? 'none yet');
}

Future<void> _runTableHelpers(DataSource ds) async {
  io.newLine();
  io.section('Ad-hoc Table Demo');

  // Using DataSource.table() for joins
  final pivotPreview = await ds
      .table('post_tags')
      .join('tags', 'tags.id', '=', 'post_tags.tag_id')
      .selectRaw('post_tags.post_id', alias: 'post_id')
      .selectRaw('tags.name', alias: 'tag_name')
      .orderBy('post_id')
      .get();

  if (pivotPreview.isEmpty) {
    io.info('No post-tag associations found.');
  } else {
    io.info('Post-tag associations:');
    for (final row in pivotPreview) {
      io.twoColumnDetail('  Post ${row['post_id']}', '${row['tag_name']}');
    }
  }
}

Future<void> _runPretendPreview(DataSource ds) async {
  io.newLine();
  io.section('Pretend Mode Preview');

  // Using DataSource.pretend() to capture SQL without executing
  final statements = await ds.pretend(() async {
    await ds.repo<User>().insert(
      User(
        email: 'pretend-${DateTime.now().millisecondsSinceEpoch}@example.com',
        name: 'Preview User',
        active: false,
        createdAt: DateTime.now().toUtc(),
        updatedAt: DateTime.now().toUtc(),
      ),
    );
  });

  io.info('SQL that would be executed:');
  for (final entry in statements) {
    io.writeln(io.style.muted('  ${entry.sql}'));
  }
}

Future<void> _runModelCrudShowcase(DataSource ds) async {
  io.newLine();
  io.section('Repository Helpers');

  // Using DataSource.repo<T>() for CRUD operations
  final tagRepo = ds.repo<Tag>();
  final now = DateTime.now().toUtc();
  final demoName = 'playground-demo-${now.microsecondsSinceEpoch}';

  await tagRepo.insert(Tag(name: demoName, createdAt: now, updatedAt: now));

  final inserted = await ds
      .query<Tag>()
      .whereEquals('name', demoName)
      .firstOrFail();
  io.writeln('${io.style.success('✓')} Inserted tag #${inserted.id} (${io.style.emphasize(demoName)})');

  final renamed = Tag(
    id: inserted.id,
    name: '$demoName-updated',
    createdAt: inserted.createdAt,
    updatedAt: DateTime.now().toUtc(),
  );
  await tagRepo.updateMany([renamed]);
  io.writeln('${io.style.success('✓')} Renamed demo tag to ${io.style.emphasize(renamed.name)}');

  await tagRepo.deleteByKeys([
    {'id': renamed.id},
  ]);
  io.writeln('${io.style.success('✓')} Deleted temporary tag record');
}

Future<void> _runRelationQueryShowcase(DataSource ds) async {
  io.newLine();
  io.section('Relation-aware Queries');

  final relationRows = await ds
      .query<Post>()
      .withCount('comments', alias: 'comments_count')
      .withExists('comments', alias: 'has_comments')
      .whereHas('tags', (builder) => builder.whereIn('name', ['dart', 'orm']))
      .orderByRelation('comments', descending: true)
      .limit(2)
      .rows();

  for (final row in relationRows) {
    final post = row.model;
    final count = row.row['comments_count'];
    final hasComments = row.row['has_comments'];
    io.writeln(
      '${io.style.success('•')} ${io.style.emphasize(post.title)} → $count comments (exists: $hasComments)',
    );
  }

  final eager = await ds
      .query<Post>()
      .withRelation('comments')
      .withRelation('tags')
      .limit(1)
      .rows();

  if (eager.isNotEmpty) {
    final row = eager.first;
    final commentBodies = row
        .relationList<Comment>('comments')
        .map((comment) => comment.body)
        .toList();
    final tagNames = row
        .relationList<Tag>('tags')
        .map((tag) => tag.name)
        .toList();
    io.info('Eager loaded "${row.model.title}":');
    io.twoColumnDetail('  Tags', tagNames.join(', '));
    io.twoColumnDetail('  Comments', commentBodies.join(', '));
  }
}

Future<void> _runPaginationShowcase(DataSource ds) async {
  io.newLine();
  io.section('Pagination Helpers');

  final page = await ds
      .query<Post>()
      .orderBy('id')
      .paginate(perPage: 2, page: 1);
  io.twoColumnDetail('paginate()', 'items=${page.items.length}, total=${page.total}, hasMore=${page.hasMorePages}');

  final simple = await ds
      .query<Post>()
      .orderBy('id')
      .simplePaginate(perPage: 2, page: 1);
  io.twoColumnDetail('simplePaginate()', 'items=${simple.items.length}, hasMore=${simple.hasMorePages}');

  final cursor = await ds
      .query<Post>()
      .orderBy('id')
      .cursorPaginate(perPage: 1);
  io.twoColumnDetail('cursorPaginate()', 'nextCursor=${cursor.nextCursor}, hasMore=${cursor.hasMore}');
}

Future<void> _runChunkingShowcase(DataSource ds) async {
  io.newLine();
  io.section('Chunk + chunkById Demos');

  await ds.query<Post>().orderBy('id').chunk(2, (rows) {
    final ids = rows.map((row) => row.model.id).toList();
    io.twoColumnDetail('chunk()', 'processed post IDs $ids');
    return true;
  });

  await ds.query<Comment>().chunkById(1, (rows) {
    final bodies = rows.map((row) => row.model.body).toList();
    io.twoColumnDetail('chunkById()', 'latest comments $bodies');
    return true;
  });
}

Future<void> _runTransactionShowcase(DataSource ds) async {
  io.newLine();
  io.section('Transaction Demo');

  // Using DataSource.transaction() for atomic operations
  final now = DateTime.now().toUtc();
  final tempTagName = 'tx-demo-${now.microsecondsSinceEpoch}';

  try {
    await ds.transaction(() async {
      // Create a tag inside transaction
      await ds.repo<Tag>().insert(
        Tag(name: tempTagName, createdAt: now, updatedAt: now),
      );

      // Verify it exists
      final exists = await ds
          .query<Tag>()
          .whereEquals('name', tempTagName)
          .exists();
      io.twoColumnDetail('Tag created in transaction', exists ? 'yes' : 'no');

      // Clean up inside same transaction
      await ds.query<Tag>().whereEquals('name', tempTagName).forceDelete();
      io.writeln('${io.style.success('✓')} Tag deleted in transaction');
    });
    io.success('Transaction committed successfully');
  } catch (e) {
    io.error('Transaction rolled back: $e');
  }
}
