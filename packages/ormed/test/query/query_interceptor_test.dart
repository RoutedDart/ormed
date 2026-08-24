import 'package:ormed/ormed.dart';
import 'package:test/test.dart';

void main() {
  test('runs interceptors in order and supports short-circuiting', () async {
    final calls = <String>[];
    final pipeline = QueryInterceptorPipeline(
      driverName: 'test',
      interceptors: [
        _RecordingInterceptor('first', calls),
        _RecordingInterceptor('second', calls),
      ],
    );
    final context = QueryExecutionContext(
      driverName: 'test',
      sql: 'SELECT 1',
      operationName: 'SELECT',
      querySummary: 'SELECT test',
    );

    final result = await pipeline.run(context, () async {
      calls.add('driver');
      return 42;
    });

    expect(result, 42);
    expect(calls, ['first:before', 'second:before', 'driver']);

    final blocked = QueryInterceptorPipeline(
      driverName: 'test',
      interceptors: [_ShortCircuitInterceptor()],
    );
    expect(await blocked.run(context, () async => 'driver'), 'intercepted');
  });

  test('streams through stream interceptors', () async {
    final pipeline = QueryInterceptorPipeline(
      driverName: 'test',
      interceptors: [_StreamInterceptor()],
    );
    final context = QueryExecutionContext(
      driverName: 'test',
      sql: 'SELECT 1',
      operationName: 'SELECT',
      querySummary: 'SELECT test',
    );

    expect(
      await pipeline
          .runStream(context, () => Stream<int>.fromIterable([1, 2]))
          .toList(),
      [2, 4],
    );
  });
}

class _RecordingInterceptor extends QueryInterceptor {
  _RecordingInterceptor(this.name, this.calls);

  final String name;
  final List<String> calls;

  @override
  Future<T> intercept<T>(
    QueryExecutionContext context,
    Future<T> Function() next,
  ) async {
    calls.add('$name:before');
    return next();
  }
}

class _ShortCircuitInterceptor extends QueryInterceptor {
  @override
  Future<T> intercept<T>(
    QueryExecutionContext context,
    Future<T> Function() next,
  ) async {
    return 'intercepted' as T;
  }
}

class _StreamInterceptor extends QueryInterceptor {
  @override
  Future<T> intercept<T>(
    QueryExecutionContext context,
    Future<T> Function() next,
  ) => next();

  @override
  Stream<T> interceptStream<T>(
    QueryExecutionContext context,
    Stream<T> Function() next,
  ) => next().map((value) => ((value as int) * 2) as T);
}
