import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart' as dotel;
import 'package:dartastic_opentelemetry/testing.dart';
import 'package:ormed/ormed.dart';
import 'package:test/test.dart';

void main() {
  late InMemorySpanExporter exporter;

  setUpAll(() async {
    exporter = InMemorySpanExporter();
    await dotel.OTel.initialize(
      serviceName: 'ormed-tests',
      spanProcessor: dotel.SimpleSpanProcessor(exporter),
      enableMetrics: false,
      enableLogs: false,
    );
  });

  setUp(() => exporter.clear());

  test('creates a database span from an execution interceptor', () async {
    final pipeline = QueryInterceptorPipeline(
      driverName: 'sqlite',
      connectionName: 'default',
      interceptors: [OrmOpenTelemetryInterceptor(includeSql: true)],
    );

    await pipeline.run(
      QueryExecutionContext(
        driverName: 'sqlite',
        connectionName: 'default',
        sql: 'SELECT * FROM users WHERE id = ?',
        parameters: [1],
        operationName: 'SELECT',
        querySummary: 'SELECT users',
        collectionName: 'users',
      ),
      () async => 1,
    );

    final span = exporter.findSpanByName('ormed.db.select users');
    expect(span, isNotNull);
    expect(span!.attributes.getString('db.system'), 'sqlite');
    expect(span.attributes.getString('db.query.text'), contains('SELECT'));
    expect(span.attributes.getInt('db.operation.parameter_count'), 1);
  });
}
