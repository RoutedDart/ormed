import 'package:analyzer/dart/element/element.dart';
import '../model_context.dart';

class CompanionClassEmitter {
  CompanionClassEmitter(this.context);

  final ModelContext context;

  String emit() {
    final buffer = StringBuffer();
    final className = context.className;
    // Simple pluralization: add 's'
    // TODO: Allow configuration or use a proper pluralizer
    final companionName = '${className}s';

    buffer.writeln('class $companionName {');
    buffer.writeln('  const $companionName._();');
    buffer.writeln();

    buffer.writeln('  static Query<$className> query([String? connection]) =>');
    buffer.writeln('      Model.query<$className>(connection: connection);');
    buffer.writeln();

    buffer.writeln(
      '  static Future<$className?> find(Object id, {String? connection}) =>',
    );
    buffer.writeln('      Model.find<$className>(id, connection: connection);');
    buffer.writeln();

    buffer.writeln(
      '  static Future<$className> findOrFail(Object id, {String? connection}) =>',
    );
    buffer.writeln(
      '      Model.findOrFail<$className>(id, connection: connection);',
    );
    buffer.writeln();

    buffer.writeln(
      '  static Future<List<$className>> all({String? connection}) =>',
    );
    buffer.writeln('      Model.all<$className>(connection: connection);');
    buffer.writeln();

    buffer.writeln('  static Future<int> count({String? connection}) =>');
    buffer.writeln('      Model.count<$className>(connection: connection);');
    buffer.writeln();

    buffer.writeln('  static Future<bool> exists({String? connection}) =>');
    buffer.writeln('      Model.exists<$className>(connection: connection);');
    buffer.writeln();

    buffer.writeln('  static Query<$className> where(');
    buffer.writeln('    String column,');
    buffer.writeln('    String operator,');
    buffer.writeln('    dynamic value, {');
    buffer.writeln('    String? connection,');
    buffer.writeln(
      '  }) => Model.where<$className>(column, operator, value, connection: connection);',
    );
    buffer.writeln();

    buffer.writeln('  static Query<$className> whereIn(');
    buffer.writeln('    String column,');
    buffer.writeln('    List<dynamic> values, {');
    buffer.writeln('    String? connection,');
    buffer.writeln(
      '  }) => Model.whereIn<$className>(column, values, connection: connection);',
    );
    buffer.writeln();

    buffer.writeln('  static Query<$className> orderBy(');
    buffer.writeln('    String column, {');
    buffer.writeln('    String direction = "asc",');
    buffer.writeln('    String? connection,');
    buffer.writeln(
      '  }) => Model.orderBy<$className>(column, direction: direction, connection: connection);',
    );
    buffer.writeln();

    buffer.writeln(
      '  static Query<$className> limit(int count, {String? connection}) =>',
    );
    buffer.writeln(
      '      Model.limit<$className>(count, connection: connection);',
    );
    buffer.writeln();

    // Add other methods as needed (create, insert, etc.)
    // For now, these are the ones we implemented in Model (or planned to)

    // TODO: Re-enable scopes generation after fixing ParameterElement type issue
    // for (final scope in context.scopes) {
    //   // Skip the first parameter (Query<T>)
    //   final visibleParams = scope.parameters.skip(1);
    //   final paramSignature = visibleParams
    //       .map(
    //         (p) =>
    //             '${(p as ParameterElement).type.getDisplayString(withNullability: true)} ${p.name}',
    //       )
    //       .join(', ');
    //   final args = visibleParams
    //       .map((p) => (p as ParameterElement).name)
    //       .join(', ');
    //   final queryArg = 'Model.query<$className>(connection: connection)';

    //   buffer.writeln(
    //     '  static Query<$className> ${scope.name}($paramSignature${paramSignature.isNotEmpty ? ', ' : ''}{String? connection}) =>',
    //   );
    //   buffer.writeln(
    //     '      $className.${scope.name}($queryArg${args.isNotEmpty ? ', ' : ''}$args);',
    //   );
    //   buffer.writeln();
    // }

    buffer.writeln('}');
    buffer.writeln();

    return buffer.toString();
  }
}
