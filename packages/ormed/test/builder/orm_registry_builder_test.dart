import 'package:ormed/src/builder/orm_registry_builder.dart';
import 'package:test/test.dart';

void main() {
  test('renderRegistryContent outputs imports and definitions', () {
    final content = renderRegistryContent([
      ModelSummary(
        className: 'User',
        importPath: 'src/user.dart',
        definition: 'UserOrmDefinition.definition',
        hasFactory: false,
      ),
      ModelSummary(
        className: 'Post',
        importPath: 'src/post.dart',
        definition: 'PostOrmDefinition.definition',
        hasFactory: false,
      ),
    ]);

    expect(content, contains("import 'src/post.dart';"));
    expect(content, contains("import 'src/user.dart';"));
    expect(content, contains('PostOrmDefinition.definition'));
    expect(content, contains('UserOrmDefinition.definition'));
    expect(content, contains('buildOrmRegistry()'));
  });

  test('renderRegistryContent outputs registerOrmFactories for models with hasFactory', () {
    final content = renderRegistryContent([
      ModelSummary(
        className: 'User',
        importPath: 'src/user.dart',
        definition: 'UserOrmDefinition.definition',
        hasFactory: true,
      ),
      ModelSummary(
        className: 'Post',
        importPath: 'src/post.dart',
        definition: 'PostOrmDefinition.definition',
        hasFactory: false,
      ),
    ]);

    expect(content, contains('registerOrmFactories()'));
    expect(content, contains('ModelFactoryRegistry.registerIfAbsent<User>(UserOrmDefinition.definition)'));
    expect(content, isNot(contains('ModelFactoryRegistry.registerIfAbsent<Post>')));
    expect(content, contains('buildOrmRegistryWithFactories()'));
  });
}
