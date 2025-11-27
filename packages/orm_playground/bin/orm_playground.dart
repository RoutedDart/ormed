import 'dart:io';

import 'package:ormed/ormed.dart';
import 'package:orm_playground/orm_playground.dart';

import '../database/seeders.dart' as playground_seeders;

Future<void> main(List<String> arguments) async {
  final logSql =
      arguments.contains('--sql') ||
      Platform.environment['PLAYGROUND_LOG_SQL'] == 'true';
  final seedOverrides = _extractSeedArguments(arguments);
  final database = PlaygroundDatabase();
  final connection = await database.open();
  try {
    await connection.ensureLedgerInitialized();
    if (!await _schemaReady(connection)) {
      stdout.writeln(
        'Run the ORM CLI to apply migrations:\n'
        '  dart run packages/orm/orm_cli/bin/orm.dart apply '
        '--config orm_playground/orm.yaml',
      );
      return;
    }

    await playground_seeders.seedPlayground(
      connection,
      names: seedOverrides.isEmpty ? null : seedOverrides,
    );
    if (logSql) {
      connection.beforeExecuting((statement) {
        stdout.writeln('[SQL] ${statement.sqlWithBindings}');
      });
    }
    await _printPostSummaries(connection);
    await _runQueryBuilderShowcase(connection);
    await _runTableHelpers(connection);
    await _runPretendPreview(connection);
    await _runModelCrudShowcase(connection);
    await _runRelationQueryShowcase(connection);
    await _runPaginationShowcase(connection);
    await _runChunkingShowcase(connection);
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

Future<bool> _schemaReady(OrmConnection connection) async {
  final driver = connection.driver;
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

Future<void> _printPostSummaries(OrmConnection connection) async {
  final query = connection
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

Future<void> _runQueryBuilderShowcase(OrmConnection connection) async {
  stdout.writeln('\nQuery builder helpers:');
  final rows = await connection
      .query<Post>()
      .withCount('comments', alias: 'comments_count')
      .orderBy('published_at', descending: true)
      .limit(3)
      .get();
  stdout.writeln('Showing ${rows.length} published posts with comment counts.');

  final activeUserIds = await connection
      .table('users')
      .whereEquals('active', true)
      .pluck<int>('id');
  stdout.writeln('Active user ids: $activeUserIds');

  final latestComment = await connection
      .query<Comment>()
      .orderBy('created_at', descending: true)
      .firstOrNull();
  stdout.writeln('Most recent comment: ${latestComment?.body ?? 'none yet'}');
}

Future<void> _runTableHelpers(OrmConnection connection) async {
  stdout.writeln('\nAd-hoc table demo:');
  final pivotPreview = await connection
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

Future<void> _runPretendPreview(OrmConnection connection) async {
  stdout.writeln('\nPretend mode preview:');
  final statements = await connection.pretend(() async {
    await connection.repository<User>().insert(
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

Future<void> _runModelCrudShowcase(OrmConnection connection) async {
  stdout.writeln('\nRepository helpers:');
  final tagRepo = connection.repository<Tag>();
  final now = DateTime.now().toUtc();
  final demoName = 'playground-demo-${now.microsecondsSinceEpoch}';
  await tagRepo.insert(
    Tag(name: demoName, createdAt: now, updatedAt: now),
    returning: false,
  );
  final inserted = await connection
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

Future<void> _runRelationQueryShowcase(OrmConnection connection) async {
  stdout.writeln('\nRelation-aware queries:');
  final relationRows = await connection
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

  final eager = await connection
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

Future<void> _runPaginationShowcase(OrmConnection connection) async {
  stdout.writeln('\nPagination helpers:');
  final page = await connection
      .query<Post>()
      .orderBy('id')
      .paginate(perPage: 2, page: 1);
  stdout.writeln(
    'paginate => items=${page.items.length}, total=${page.total}, hasMore=${page.hasMorePages}',
  );

  final simple = await connection
      .query<Post>()
      .orderBy('id')
      .simplePaginate(perPage: 2, page: 1);
  stdout.writeln(
    'simplePaginate => items=${simple.items.length}, hasMore=${simple.hasMorePages}',
  );

  final cursor = await connection
      .query<Post>()
      .orderBy('id')
      .cursorPaginate(perPage: 1);
  stdout.writeln(
    'cursorPaginate => nextCursor=${cursor.nextCursor}, hasMore=${cursor.hasMore}',
  );
}

Future<void> _runChunkingShowcase(OrmConnection connection) async {
  stdout.writeln('\nChunk + chunkById demos:');
  await connection.query<Post>().orderBy('id').chunk(2, (rows) {
    final ids = rows.map((row) => row.model.id).toList();
    stdout.writeln('chunk => processed post IDs $ids');
    return true;
  });

  await connection.query<Comment>().chunkById(1, (rows) {
    final bodies = rows.map((row) => row.model.body).toList();
    stdout.writeln('chunkById => latest comments $bodies');
    return true;
  });
}
