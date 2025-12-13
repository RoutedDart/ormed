import '../descriptors.dart';
import '../helpers.dart';
import '../model_context.dart';

/// Emits Insert/Update DTOs for a given model.
/// DTOs are lightweight: optional fields, column-name maps, no behavior.
class ModelDtoEmitter {
  ModelDtoEmitter(this.context);

  final ModelContext context;

  String emit() {
    final buffer = StringBuffer();
    final className = context.className;
    final trackedName = context.trackedModelClassName;

    _writeInsertDto(buffer, className, trackedName, context.fields);
    buffer.writeln();
    _writeUpdateDto(buffer, className, trackedName, context.fields);
    buffer.writeln();

    return buffer.toString();
  }

  void _writeInsertDto(
    StringBuffer buffer,
    String className,
    String trackedName,
    List<FieldDescriptor> fields,
  ) {
    final insertable = fields.where((f) => !f.isVirtual && !f.autoIncrement);

    buffer.writeln('/// Insert DTO for [$className].');
    buffer.writeln('///');
    buffer.writeln(
      '/// Auto-increment/DB-generated fields are omitted by default.',
    );
    buffer.writeln(
      'class ${className}InsertDto implements InsertDto<$trackedName> {',
    );
    if (insertable.isEmpty) {
      buffer.writeln('  const ${className}InsertDto();');
    } else {
      buffer.write('  const ${className}InsertDto({');
      for (final field in insertable) {
        buffer.write('this.${field.name}, ');
      }
      buffer.writeln('});');
    }

    for (final field in insertable) {
      buffer.writeln('  final ${field.dartType}? ${field.name};');
    }
    buffer.writeln();

    buffer.writeln('  @override');
    buffer.writeln('  Map<String, Object?> toMap() {');
    buffer.writeln('    return <String, Object?>{');
    for (final field in insertable) {
      buffer.writeln(
        "      if (${field.name} != null) '${escape(field.columnName)}': ${field.name},",
      );
    }
    buffer.writeln('    };');
    buffer.writeln('  }');
    buffer.writeln('}');
  }

  void _writeUpdateDto(
    StringBuffer buffer,
    String className,
    String trackedName,
    List<FieldDescriptor> fields,
  ) {
    final updatable = fields.where((f) => !f.isVirtual);

    buffer.writeln('/// Update DTO for [$className].');
    buffer.writeln('///');
    buffer.writeln(
      '/// All fields are optional; only provided entries are used in SET clauses.',
    );
    buffer.writeln(
      'class ${className}UpdateDto implements UpdateDto<$trackedName> {',
    );
    if (updatable.isEmpty) {
      buffer.writeln('  const ${className}UpdateDto();');
    } else {
      buffer.write('  const ${className}UpdateDto({');
      for (final field in updatable) {
        buffer.write('this.${field.name}, ');
      }
      buffer.writeln('});');
    }

    for (final field in updatable) {
      buffer.writeln('  final ${field.dartType}? ${field.name};');
    }
    buffer.writeln();

    buffer.writeln('  @override');
    buffer.writeln('  Map<String, Object?> toMap() {');
    buffer.writeln('    return <String, Object?>{');
    for (final field in updatable) {
      buffer.writeln(
        "      if (${field.name} != null) '${escape(field.columnName)}': ${field.name},",
      );
    }
    buffer.writeln('    };');
    buffer.writeln('  }');
    buffer.writeln('}');
  }
}
