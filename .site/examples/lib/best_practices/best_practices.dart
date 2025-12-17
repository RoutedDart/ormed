// Best practices examples for documentation
// ignore_for_file: unused_local_variable

import 'package:ormed/ormed.dart';

import '../models/user.dart';
import '../models/user.orm.dart';
import '../models/post.dart';
import '../models/post.orm.dart';

// #region n-plus-one-bad
// BAD: N+1 problem - one query per user
Future<void> nPlusOneBad(DataSource dataSource) async {
  final users = await dataSource.query<$User>().get();

  for (final user in users) {
    // This triggers a query for EACH user!
    await user.load(['posts']);
    print('${user.name} has ${user.posts?.length} posts');
  }
}
// #endregion n-plus-one-bad

// #region n-plus-one-good
// GOOD: Eager loading - just 2 queries total
Future<void> nPlusOneGood(DataSource dataSource) async {
  final users = await dataSource
      .query<$User>()
      .with_(['posts']) // Load all posts in one query
      .get();

  for (final user in users) {
    // Already loaded, no additional query
    print('${user.name} has ${user.posts?.length} posts');
  }
}
// #endregion n-plus-one-good

// #region aggregate-bad
// BAD: Loads all related records just to count
Future<void> aggregateBad(DataSource dataSource) async {
  final user = await dataSource.query<$User>().with_(['posts']).first();
  final postCount = user?.posts?.length ?? 0;
}
// #endregion aggregate-bad

// #region aggregate-good
// GOOD: Uses database to count
Future<void> aggregateGood(DataSource dataSource) async {
  final user = await dataSource.query<$User>().first();
  await user?.loadCount(['posts']);
  final postCount = user?.getAttribute<int>('posts_count') ?? 0;
}
// #endregion aggregate-good

// #region select-bad
// BAD: Loads all columns when you only need emails
Future<void> selectBad(DataSource dataSource) async {
  final users = await dataSource.query<$User>().get();
  final emails = users.map((u) => u.email).toList();
}
// #endregion select-bad

// #region select-good
// GOOD: Only select what you need
Future<void> selectGood(DataSource dataSource) async {
  final emails = await dataSource
      .query<$User>()
      .pluck<String>('email');
}
// #endregion select-good

// #region pagination
Future<void> paginationExample(DataSource dataSource) async {
  // Use pagination for large datasets
  final page = 1;
  final perPage = 20;

  final users = await dataSource
      .query<$User>()
      .orderBy('id')
      .limit(perPage)
      .offset((page - 1) * perPage)
      .get();
}
// #endregion pagination

// #region indexes
// Ensure indexes on frequently queried columns
// In your migration:
// schema.create('users', (table) {
//   table.index(['email']);
//   table.index(['created_at']);
//   table.index(['status', 'created_at']); // Composite for common filters
// });
// #endregion indexes

// #region when-eager
// Use eager loading when:
// - Processing multiple records
// - You KNOW you need the relation data
// - Building API responses with nested data
Future<void> whenToUseEagerLoading(DataSource dataSource) async {
  final posts = await dataSource
      .query<$Post>()
      .with_(['author', 'comments'])
      .get();

  // Build response with all data already loaded
  for (final post in posts) {
    print('${post.title} by ${post.author?.name}');
  }
}
// #endregion when-eager

// #region when-lazy
// Use lazy loading when:
// - You might not need the relation
// - Processing single records
// - Conditional logic determines if relation is needed
Future<void> whenToUseLazyLoading(DataSource dataSource) async {
  final post = await dataSource.query<$Post>().find(1);

  if (post != null && post.getAttribute<bool>('featured') == true) {
    // Only load if needed
    await post.load(['author', 'comments']);
  }
}
// #endregion when-lazy

// #region load-missing
// Use loadMissing to avoid reloading
Future<void> loadMissingExample(DataSource dataSource) async {
  final post = await dataSource.query<$Post>().with_(['author']).first();

  if (post != null) {
    // Won't reload author, only loads comments
    await post.loadMissing(['author', 'comments']);
  }
}
// #endregion load-missing

// #region prevent-lazy
// Enable lazy loading prevention during development
void preventLazyLoadingExample() {
  // In main.dart or test setup
  // if (kDebugMode) {
  //   Model.preventLazyLoading();
  // }

  // Now accessing unloaded relations throws an exception
  // This helps catch N+1 issues during development
}
// #endregion prevent-lazy

// #region extend-model
// Add business logic to your models
// In user.dart:
// extension UserExtensions on User {
//   String get displayName => name ?? email.split('@').first;
//   bool get isVerified => emailVerifiedAt != null;
//   bool get canPost => isVerified && active;
// }
// #endregion extend-model

// #region immutable-model
// Models should be immutable - use tracked models for changes
Future<void> immutableModelExample(DataSource dataSource) async {
  final user = await dataSource.query<$User>().find(1);

  if (user != null) {
    // Don't modify original, use setAttribute on tracked model
    user.setAttribute('name', 'New Name');
    await dataSource.repo<$User>().update(user);

    // Or use update DTO
    await dataSource.repo<$User>().update(
          UserUpdateDto(name: 'New Name'),
          where: {'id': 1},
        );
  }
}
// #endregion immutable-model

// #region soft-deletes-wise
// Use soft deletes wisely
// Good for:
// - Audit trails
// - Recoverable deletions
// - Legal/compliance requirements

// Avoid for:
// - High-volume ephemeral data
// - Storage-constrained environments
// - Data without recovery needs
// #endregion soft-deletes-wise

// #region error-typed-exceptions
Future<void> typedExceptionsExample(DataSource dataSource, String email) async {
  try {
    final user = await dataSource.query<$User>()
        .whereEquals('email', email)
        .firstOrFail();
  } on ModelNotFoundException catch (e) {
    print('User not found: $e');
  }
}
// #endregion error-typed-exceptions

// #region error-validate-before-save-model
@OrmModel(table: 'validated_users')
class ValidatedUser extends Model<ValidatedUser> {
  const ValidatedUser({required this.id, required this.email, required this.age});

  @OrmField(isPrimaryKey: true, autoIncrement: true)
  final int id;
  final String email;
  final int age;

  void validate() {
    if (!email.contains('@')) {
      throw ArgumentError('Invalid email format');
    }
    if (age < 0 || age > 150) {
      throw ArgumentError('Invalid age');
    }
  }
}
// #endregion error-validate-before-save-model

// #region error-validate-before-save-usage
Future<void> validateBeforeSaveExample(DataSource dataSource, ValidatedUser user) async {
  // Before inserting
  user.validate();
  await dataSource.repo<$ValidatedUser>().insert(user);
}
// #endregion error-validate-before-save-usage

// #region error-transactions
Future<void> transactionExample(
  DataSource dataSource,
  int fromAccountId,
  int toAccountId,
  double amount,
  double sourceBalance,
  double destBalance,
) async {
  await dataSource.transaction(() async {
    await dataSource.query<$User>()
        .whereEquals('id', fromAccountId)
        .update({'balance': sourceBalance - amount});

    await dataSource.query<$User>()
        .whereEquals('id', toAccountId)
        .update({'balance': destBalance + amount});
  });
}
// #endregion error-transactions

// #region testing-in-memory
// Use in-memory databases for fast, isolated tests
// driver: SqliteDriverAdapter.inMemory()
// #endregion testing-in-memory

// #region testing-factories
Future<void> testFactoriesExample(DataSource dataSource) async {
  final userFactory = Model.factory<User>();

  for (var i = 0; i < 100; i++) {
    await userFactory
        .seed(i)
        .withField('email', 'user_$i@test.com')
        .create(context: dataSource.context);
  }

  // expect(await dataSource.query<$User>().count(), equals(100));
}
// #endregion testing-factories

// #region security-sql-injection-bad
// BAD: SQL injection risk
Future<void> sqlInjectionBadExample(DataSource dataSource, String userInput) async {
  // DON'T DO THIS!
  // final users = await dataSource.query<$User>()
  //     .whereRaw("email = '\$userInput'")
  //     .get();
}
// #endregion security-sql-injection-bad

// #region security-sql-injection-good
// GOOD: Parameterized queries
Future<void> sqlInjectionGoodExample(DataSource dataSource, String userInput) async {
  final users = await dataSource.query<$User>()
      .whereEquals('email', userInput)
      .get();
}
// #endregion security-sql-injection-good

// #region security-validate-relations
Future<void> validateRelationsExample(DataSource dataSource, Post post, User author) async {
  final validAuthor = await dataSource.query<$User>()
      .whereEquals('id', author.id)
      .whereEquals('active', true)
      .firstOrNull();

  if (validAuthor == null) {
    throw Exception('Invalid author');
  }

  post.associate('author', validAuthor);
  await post.save();
}
// #endregion security-validate-relations

// #region security-scopes-multitenancy
void scopesMultitenancyExample(QueryContext context, int currentTenantId) {
  context.scopeRegistry.registerScope<$Post>((query) {
    query.whereEquals('tenant_id', currentTenantId);
  });

  // All queries automatically filtered
  // final posts = await dataSource.query<$Post>().get();
  // SQL: SELECT * FROM posts WHERE tenant_id = ?
}
// #endregion security-scopes-multitenancy

// #region security-dto
class UserDto {
  final int id;
  final String email;
  // No passwordHash or apiToken

  UserDto({required this.id, required this.email});

  factory UserDto.fromModel(User user) => UserDto(
    id: user.id,
    email: user.email,
  );
}

Future<List<UserDto>> getUserDtosExample(DataSource dataSource) async {
  final users = await dataSource.query<$User>().get();
  return users.map(UserDto.fromModel).toList();
}
// #endregion security-dto

abstract class $ValidatedUser {}
extension $ValidatedUserRepo on Repository<$User> {
  Future<ValidatedUser> insert(ValidatedUser user) => throw UnimplementedError();
}
