library;

import 'package:ormed/ormed.dart';
import 'package:ormed/testing.dart';

import '../../models.dart';
import '../seed_data.dart';

/// Seeder for User model in driver tests
class UserSeeder extends DatabaseSeeder {
  UserSeeder(super.connection, {this.suffix});

  final String? suffix;

  @override
  Future<void> run() async {
    final users = buildDefaultUsers(suffix: suffix);
    await seed<User>(
      users
          .map((u) => {'id': u.id, 'email': u.email, 'active': u.active})
          .toList(),
    );
  }
}

/// Seeder for Author model in driver tests
class AuthorSeeder extends DatabaseSeeder {
  AuthorSeeder(super.connection);

  @override
  Future<void> run() async {
    await seed<Author>(
      defaultAuthors.map((a) => {'id': a.id, 'name': a.name}).toList(),
    );
  }
}

/// Seeder for Post model in driver tests
class PostSeeder extends DatabaseSeeder {
  PostSeeder(super.connection);

  @override
  Future<void> run() async {
    final posts = buildDefaultPosts();
    await seed<Post>(
      posts
          .map(
            (p) => {
              'id': p.id,
              'author_id': p.authorId,
              'title': p.title,
              'published_at': p.publishedAt.toIso8601String(),
            },
          )
          .toList(),
    );
  }
}

/// Seeder for Tag model in driver tests
class TagSeeder extends DatabaseSeeder {
  TagSeeder(super.connection);

  @override
  Future<void> run() async {
    await seed<Tag>(
      defaultTags.map((t) => {'id': t.id, 'label': t.label}).toList(),
    );
  }
}

/// Seeder for PostTag model in driver tests
class PostTagSeeder extends DatabaseSeeder {
  PostTagSeeder(super.connection);

  @override
  Future<void> run() async {
    await seed<PostTag>(
      defaultPostTags
          .map((pt) => {'post_id': pt.postId, 'tag_id': pt.tagId})
          .toList(),
    );
  }
}

/// Seeder for Image model in driver tests
class ImageSeeder extends DatabaseSeeder {
  ImageSeeder(super.connection);

  @override
  Future<void> run() async {
    await seed<Image>(
      defaultImages.map((i) => {'id': i.id, 'label': i.label}).toList(),
    );
  }
}

/// Seeder for Photo model in driver tests
class PhotoSeeder extends DatabaseSeeder {
  PhotoSeeder(super.connection);

  @override
  Future<void> run() async {
    await seed<Photo>(
      defaultPhotos
          .map(
            (p) => {
              'id': p.id,
              'imageable_id': p.imageableId,
              'imageable_type': p.imageableType,
              'path': p.path,
            },
          )
          .toList(),
    );
  }
}

/// Seeder for Comment model in driver tests
class CommentSeeder extends DatabaseSeeder {
  CommentSeeder(super.connection);

  @override
  Future<void> run() async {
    await seed<Comment>(defaultComments);
  }
}

/// Seeder for Article model in driver tests
class ArticleSeeder extends DatabaseSeeder {
  ArticleSeeder(super.connection);

  @override
  Future<void> run() async {
    await seed<Article>(
      sampleArticles
          .map(
            (a) => {
              'id': a.id,
              'title': a.title,
              if (a.body != null) 'body': a.body,
              'status': a.status,
              'rating': a.rating,
              'priority': a.priority,
              'published_at': a.publishedAt.toIso8601String(),
              if (a.reviewedAt != null)
                'reviewed_at': a.reviewedAt!.toIso8601String(),
              'category_id': a.categoryId,
            },
          )
          .toList(),
    );
  }
}

/// Main seeder that seeds the complete graph of driver test data
///
/// This seeder calls all other seeders in the correct order to maintain
/// referential integrity.
///
/// Example:
/// ```dart
/// final manager = createDriverTestSchemaManager(driver);
/// await manager.setup();
/// await manager.seed(connection, [DriverTestGraphSeeder.new]);
/// ```
class DriverTestGraphSeeder extends DatabaseSeeder {
  DriverTestGraphSeeder(super.connection, {this.userSuffix});

  final String? userSuffix;

  @override
  Future<void> run() async {
    // Seed in order to maintain foreign key constraints
    await call([
      (_) => UserSeeder(connection, suffix: userSuffix),
      AuthorSeeder.new,
      PostSeeder.new,
      TagSeeder.new,
      PostTagSeeder.new,
      ImageSeeder.new,
      PhotoSeeder.new,
      CommentSeeder.new,
    ]);
  }
}

/// Seeder registry for driver tests
///
/// Use this with [runSeederRegistry] for flexible seeding in tests.
///
/// Example:
/// ```dart
/// await runSeederRegistry(
///   connection,
///   driverTestSeederRegistry,
///   names: ['UserSeeder', 'PostSeeder'],
/// );
/// ```
final List<SeederRegistration> driverTestSeederRegistry = [
  SeederRegistration(name: 'UserSeeder', factory: UserSeeder.new),
  SeederRegistration(name: 'AuthorSeeder', factory: AuthorSeeder.new),
  SeederRegistration(name: 'PostSeeder', factory: PostSeeder.new),
  SeederRegistration(name: 'TagSeeder', factory: TagSeeder.new),
  SeederRegistration(name: 'PostTagSeeder', factory: PostTagSeeder.new),
  SeederRegistration(name: 'ImageSeeder', factory: ImageSeeder.new),
  SeederRegistration(name: 'PhotoSeeder', factory: PhotoSeeder.new),
  SeederRegistration(name: 'CommentSeeder', factory: CommentSeeder.new),
  SeederRegistration(name: 'ArticleSeeder', factory: ArticleSeeder.new),
  SeederRegistration(
    name: 'DriverTestGraphSeeder',
    factory: DriverTestGraphSeeder.new,
  ),
];

/// Seed the complete driver test graph using the new TestSchemaManager pattern
///
/// This is a convenience function that uses [DriverTestGraphSeeder] to seed
/// all test data in the correct order.
///
/// Example:
/// ```dart
/// final manager = createDriverTestSchemaManager(driver);
/// await manager.setup();
/// await seedDriverTestGraph(manager, connection);
/// ```
Future<void> seedDriverTestGraph(
  TestSchemaManager manager,
  OrmConnection connection, {
  String? userSuffix,
}) async {
  await manager.seed(connection, [
    (_) => DriverTestGraphSeeder(connection, userSuffix: userSuffix),
  ]);
}
