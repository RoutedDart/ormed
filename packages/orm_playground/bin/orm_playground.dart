import 'dart:io';

import 'package:orm_playground/orm_playground.dart';
import 'package:orm_playground/src/database/seeders.dart' as playground_seeders;
import 'package:ormed/ormed.dart';

Future<void> main(List<String> arguments) async {
  final logSql =
      arguments.contains('--sql') ||
      Platform.environment['PLAYGROUND_LOG_SQL'] == 'true';
  final seedOverrides = _extractSeedArguments(arguments);

  // Create the playground database helper
  final database = PlaygroundDatabase();

  // Get the DataSource for the default tenant
  final ds = await database.dataSource();

  try {
    // Check if schema is ready
    if (!await _schemaReady(ds)) {
      stdout.writeln(
        'Run the ORM CLI to apply migrations:\n'
        '  dart run packages/orm/ormed_cli/bin/orm.dart apply '
        '--config orm_playground/orm.yaml',
      );
      return;
    }

    // Seed the database
    await playground_seeders.seedPlayground(
      ds.connection,
      names: seedOverrides.isEmpty ? null : seedOverrides,
    );

    // Enable SQL logging if requested
    if (logSql) {
      ds.beforeExecuting((statement) {
        stdout.writeln('[SQL] ${statement.sqlWithBindings}');
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
    stderr.writeln('Playground driver does not support schema inspection.');
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

  if (rows.isEmpty) {
    stdout.writeln('No posts found. Create one via the ORM CLI to continue.');
    return;
  }

  stdout.writeln('');
  stdout.writeln('Latest posts:');
  for (final row in rows) {
    final post = row.model;
    final tagList = post.tags.map((tag) => tag.name).join(', ');
    final commentCount =
        (row.row['comments_count'] as int?) ??
        row.relationList<Comment>('comments').length;
    stdout.writeln(
      '• ${post.title} '
      'by ${post.author?.name ?? 'Unknown'} '
      '($commentCount comments, tags: ${tagList.isEmpty ? 'none' : tagList})',
    );
  }

  final preview = query.toSql();
  stdout.writeln('Preview SQL: ${preview.sqlWithBindings}');
}

Future<void> _runQueryBuilderShowcase(DataSource ds) async {
  stdout.writeln('\nQuery builder helpers:');

  // Using query<T>() from DataSource
  final rows = await ds
      .query<Post>()
      .withCount('comments', alias: 'comments_count')
      .orderBy('published_at', descending: true)
      .limit(3)
      .get();
  stdout.writeln('Showing ${rows.length} published posts with comment counts.');

  // Using table() for ad-hoc queries
  final activeUserIds = await ds
      .table('users')
      .whereEquals('active', true)
      .pluck<int>('id');
  stdout.writeln('Active user ids: $activeUserIds');

  final latestComment = await ds
      .query<Comment>()
      .orderBy('created_at', descending: true)
      .firstOrNull();
  stdout.writeln('Most recent comment: ${latestComment?.body ?? 'none yet'}');
}

Future<void> _runTableHelpers(DataSource ds) async {
  stdout.writeln('\nAd-hoc table demo:');

  // Using DataSource.table() for joins
  final pivotPreview = await ds
      .table('post_tags')
      .join('tags', 'tags.id', '=', 'post_tags.tag_id')
      .selectRaw('post_tags.post_id', alias: 'post_id')
      .selectRaw('tags.name', alias: 'tag_name')
      .orderBy('post_id')
      .get();
  final formatted = pivotPreview
      .map((row) => {'post_id': row['post_id'], 'tag': row['tag_name']})
      .toList();
  stdout.writeln('Post-tag associations: $formatted');
}

Future<void> _runPretendPreview(DataSource ds) async {
  stdout.writeln('\nPretend mode preview:');

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
  for (final entry in statements) {
    stdout.writeln('Pretend SQL: ${entry.sql}');
  }
}

Future<void> _runModelCrudShowcase(DataSource ds) async {
  stdout.writeln('\nRepository helpers:');

  // Using DataSource.repo<T>() for CRUD operations
  final tagRepo = ds.repo<Tag>();
  final now = DateTime.now().toUtc();
  final demoName = 'playground-demo-${now.microsecondsSinceEpoch}';

  await tagRepo.insert(
    Tag(name: demoName, createdAt: now, updatedAt: now),
  );

  final inserted = await ds
      .query<Tag>()
      .whereEquals('name', demoName)
      .firstOrFail();
  stdout.writeln('Inserted tag #${inserted.id} ($demoName)');

  final renamed = Tag(
    id: inserted.id,
    name: '$demoName-updated',
    createdAt: inserted.createdAt,
    updatedAt: DateTime.now().toUtc(),
  );
  await tagRepo.updateMany([renamed]);
  stdout.writeln('Renamed demo tag to ${renamed.name}');

  await tagRepo.deleteByKeys([
    {'id': renamed.id},
  ]);
  stdout.writeln('Deleted temporary tag record');
}

Future<void> _runRelationQueryShowcase(DataSource ds) async {
  stdout.writeln('\nRelation-aware queries:');

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
    stdout.writeln('• ${post.title} → $count comments (exists: $hasComments)');
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
    stdout.writeln(
      'Eager loaded ${row.model.title}: tags=$tagNames / comments=$commentBodies',
    );
  }
}

Future<void> _runPaginationShowcase(DataSource ds) async {
  stdout.writeln('\nPagination helpers:');

  final page = await ds
      .query<Post>()
      .orderBy('id')
      .paginate(perPage: 2, page: 1);
  stdout.writeln(
    'paginate => items=${page.items.length}, total=${page.total}, hasMore=${page.hasMorePages}',
  );

  final simple = await ds
      .query<Post>()
      .orderBy('id')
      .simplePaginate(perPage: 2, page: 1);
  stdout.writeln(
    'simplePaginate => items=${simple.items.length}, hasMore=${simple.hasMorePages}',
  );

  final cursor = await ds
      .query<Post>()
      .orderBy('id')
      .cursorPaginate(perPage: 1);
  stdout.writeln(
    'cursorPaginate => nextCursor=${cursor.nextCursor}, hasMore=${cursor.hasMore}',
  );
}

Future<void> _runChunkingShowcase(DataSource ds) async {
  stdout.writeln('\nChunk + chunkById demos:');

  await ds.query<Post>().orderBy('id').chunk(2, (rows) {
    final ids = rows.map((row) => row.model.id).toList();
    stdout.writeln('chunk => processed post IDs $ids');
    return true;
  });

  await ds.query<Comment>().chunkById(1, (rows) {
    final bodies = rows.map((row) => row.model.body).toList();
    stdout.writeln('chunkById => latest comments $bodies');
    return true;
  });
}

Future<void> _runTransactionShowcase(DataSource ds) async {
  stdout.writeln('\nTransaction demo:');

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
      stdout.writeln('Tag created in transaction: $exists');

      // Clean up inside same transaction
      await ds.query<Tag>().whereEquals('name', tempTagName).forceDelete();
      stdout.writeln('Tag deleted in transaction');
    });
    stdout.writeln('Transaction committed successfully');
  } catch (e) {
    stdout.writeln('Transaction rolled back: $e');
  }
}
