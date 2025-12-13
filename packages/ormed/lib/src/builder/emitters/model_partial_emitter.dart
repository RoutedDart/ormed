import '../descriptors.dart';
import '../model_context.dart';

/// Emits PartialEntity for a given model.
/// Partials are fully nullable projections; `toEntity` validation is left for future
/// enhancement once required-field metadata is wired in.
class ModelPartialEmitter {
  ModelPartialEmitter(this.context);

  final ModelContext context;

  String emit() {
    final buffer = StringBuffer();
    final className = context.className;
    final trackedName = context.trackedModelClassName;

    _writePartial(buffer, className, trackedName, context.fields);
    buffer.writeln();

    return buffer.toString();
  }

  void _writePartial(
    StringBuffer buffer,
    String className,
    String trackedName,
    List<FieldDescriptor> fields,
  ) {
    final visible = fields.where((f) => !f.isVirtual);

    buffer.writeln('/// Partial projection for [$className].');
    buffer.writeln('///');
    buffer.writeln('/// All fields are nullable; intended for subset SELECTs.');
    buffer.writeln(
      'class ${className}Partial implements PartialEntity<$trackedName> {',
    );

    if (visible.isEmpty) {
      buffer.writeln('  const ${className}Partial();');
    } else {
      buffer.write('  const ${className}Partial({');
      for (final field in visible) {
        buffer.write('this.${field.name}, ');
      }
      buffer.writeln('});');
    }

    for (final field in visible) {
      buffer.writeln('  final ${field.dartType}? ${field.name};');
    }
    buffer.writeln();

    buffer.writeln('  @override');
    buffer.writeln('  $trackedName toEntity() {');
    buffer.writeln(
      "    // Basic required-field check: non-nullable fields must be present.",
    );
    for (final field in visible.where((f) => !f.isNullable)) {
      buffer.writeln(
        '    final ${field.dartType}? ${field.name}Value = ${field.name};',
      );
      buffer.writeln(
        "    if (${field.name}Value == null) throw StateError('Missing required field: ${field.name}');",
      );
    }
    buffer.writeln('    return $trackedName(');
    for (final field in visible) {
      if (!field.isNullable) {
        buffer.writeln('      ${field.name}: ${field.name}Value,');
      } else {
        buffer.writeln('      ${field.name}: ${field.name},');
      }
    }
    buffer.writeln('    );');
    buffer.writeln('  }');
    buffer.writeln('}');
  }
}
