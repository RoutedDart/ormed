import '../model_context.dart';

class ModelEventHandlerEmitter {
  const ModelEventHandlerEmitter(this.context);

  final ModelContext context;

  String emit() {
    final buffer = StringBuffer();
    final fn = 'register${context.className}EventHandlers';
    buffer.writeln('void $fn(EventBus bus) {');
    if (context.eventHandlers.isEmpty) {
      buffer.writeln(
        "  // No event handlers registered for ${context.className}.",
      );
    } else {
      for (final handler in context.eventHandlers) {
        final eventType = handler.eventType.getDisplayString();
        buffer.writeln('  bus.on<$eventType>((event) {');
        if (handler.isModelEvent) {
          buffer.writeln(
            '    if (event.modelType != ${context.className} && event.modelType != ${context.trackedModelClassName}) {',
          );
          buffer.writeln('      return;');
          buffer.writeln('    }');
        }
        // Static handlers only (instance handlers require a model instance we
        // do not construct here).
        buffer.writeln(
          '    ${context.className}.${handler.methodName}(event);',
        );
        buffer.writeln('  });');
      }
    }
    buffer.writeln('}');
    return buffer.toString();
  }
}
