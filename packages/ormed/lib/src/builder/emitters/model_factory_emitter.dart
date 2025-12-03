import '../model_context.dart';

class ModelFactoryEmitter {
  const ModelFactoryEmitter(this.context);

  final ModelContext context;

  String emit() {
    final className = context.className;
    final buffer = StringBuffer();

    buffer.writeln('class ${className}ModelFactory {');
    buffer.writeln('  const ${className}ModelFactory._();');
    buffer.writeln();

    // Static getters for definition and codec
    buffer.writeln(
      '  static ModelDefinition<$className> get definition => _\$${className}ModelDefinition;',
    );
    buffer.writeln();
    buffer.writeln(
      '  static ModelCodec<$className> get codec => definition.codec;',
    );
    buffer.writeln();

    // fromMap and toMap static methods
    buffer.writeln('  static $className fromMap(');
    buffer.writeln('    Map<String, Object?> data, {');
    buffer.writeln('    ValueCodecRegistry? registry,');
    buffer.writeln('  }) => definition.fromMap(data, registry: registry);');
    buffer.writeln();
    buffer.writeln('  static Map<String, Object?> toMap(');
    buffer.writeln('    $className model, {');
    buffer.writeln('    ValueCodecRegistry? registry,');
    buffer.writeln('  }) => definition.toMap(model, registry: registry);');
    buffer.writeln();

    // registerWith method
    buffer.writeln('  static void registerWith(ModelRegistry registry) =>');
    buffer.writeln('      registry.register(definition);');
    buffer.writeln();

    // withConnection method
    buffer.writeln(
      '  static ModelFactoryConnection<$className> withConnection(QueryContext context) =>',
    );
    buffer.writeln(
      '      ModelFactoryConnection<$className>(definition: definition, context: context);',
    );
    buffer.writeln();

    // factory method
    buffer.writeln('  static ModelFactoryBuilder<$className> factory({');
    buffer.writeln('    GeneratorProvider? generatorProvider,');
    buffer.writeln('  }) => ModelFactoryBuilder<$className>(');
    buffer.writeln('      definition: definition,');
    buffer.writeln('      generatorProvider: generatorProvider,');
    buffer.writeln('    );');

    buffer.writeln('}');
    buffer.writeln();

    return buffer.toString();
  }
}
