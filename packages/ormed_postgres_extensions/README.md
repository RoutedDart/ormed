# ormed_postgres_extensions

Postgres extension handlers for Ormed using the driver extension system.

This is an internal integration package (`publish_to: none`). Install
[`ormed_postgres`](https://pub.dev/packages/ormed_postgres) for the database
driver, then add this package when the application uses PostGIS, pgvector, or
another supported PostgreSQL extension.

## Usage modes

### Generated / model-backed usage

Use the generated registry when extension queries target typed models:

```dart
import 'dart:io';

import 'package:ormed/ormed.dart';
import 'package:ormed_postgres/ormed_postgres.dart';
import 'package:ormed_postgres_extensions/ormed_postgres_extensions.dart';
import 'package:your_app/src/models/place.orm.dart';

Future<DataSource> createDataSourceWithExtensions() async {
  final env = OrmedEnvironment.fromDirectory(Directory.current);
  final registry = ModelRegistry()..register(PlaceOrmDefinition.definition);
  final baseOptions = registry.postgresDataSourceOptionsFromEnv(
    name: 'default',
    environment: env.values,
  );
  final options = baseOptions.copyWith(
    driverExtensions: const [PostgisExtensions(), PgvectorExtensions()],
  );

  final dataSource = DataSource(options);
  await dataSource.init();
  return dataSource;
}
```

### Direct / codegen-free usage

The same extensions work with an empty registry and an ad-hoc table query:

```dart
import 'package:ormed/ormed.dart';
import 'package:ormed_postgres/ormed_postgres.dart';
import 'package:ormed_postgres_extensions/ormed_postgres_extensions.dart';

final database = await PostgresDatabase.connect(
  database: 'catalog',
  username: 'postgres',
  password: 'postgres',
  driverExtensions: const [PgvectorExtensions()],
);

final rows = await database
    .table('documents')
    .orderByPgvectorDistance(
      const PgvectorDistancePayload(
        column: 'embedding',
        vector: [0.1, 0.2, 0.3],
        metric: PgvectorDistanceMetric.l2,
      ),
    )
    .limit(10)
    .rows();
await database.close();
```

## Related packages

| Package | Use it for |
| --- | --- |
| [`ormed`](https://pub.dev/packages/ormed) | Core runtime and query APIs |
| [`ormed_postgres`](https://pub.dev/packages/ormed_postgres) | PostgreSQL driver |
| [`ormed_cli`](https://pub.dev/packages/ormed_cli) | Scaffolding and migrations |

### PostGIS

```dart
final dataSource = DataSource(
  DataSourceOptions(
    driver: PostgresDriverAdapter.fromUrl(env['POSTGRES_URL']!),
    driverExtensions: const [PostgisExtensions()],
    entities: registry.allDefinitions,
  ),
);

final payload = PostgisWithinPayload(
  column: 'location',
  point: const PostgisPoint(longitude: -122.4194, latitude: 37.7749),
  meters: 1500,
);

final preview = dataSource.query<Place>()
  .wherePostgisWithin(payload)
  .orderByPostgisDistance(
    PostgisDistancePayload(
      column: 'location',
      point: payload.point,
    ),
  )
  .selectPostgisGeoJson(
    const PostgisGeoJsonPayload(column: 'location'),
    alias: 'location_geojson',
  )
  .toSql();
```

### pgvector

```dart
final dataSource = DataSource(
  DataSourceOptions(
    driver: PostgresDriverAdapter.fromUrl(env['POSTGRES_URL']!),
    driverExtensions: const [PgvectorExtensions()],
    entities: registry.allDefinitions,
  ),
);

final orderPayload = PgvectorDistancePayload(
  column: 'embedding',
  vector: const [0.1, 0.2, 0.3],
  metric: PgvectorDistanceMetric.l2,
);

final preview = dataSource.query<AdHocRow>()
  .orderByPgvectorDistance(orderPayload)
  .toSql();
```

### pg_trgm

```dart
final rows = dataSource.context
  .table('trgm_items')
  .wherePgTrgmSimilarity(
    const PgTrgmSimilarityPayload(
      column: 'name',
      value: 'hello',
      threshold: 0.2,
    ),
  )
  .orderByPgTrgmSimilarity(
    const PgTrgmOrderPayload(column: 'name', value: 'hello'),
  )
  .rows();
```

### hstore

```dart
final rows = dataSource.context
  .table('hstore_items')
  .whereHstoreHasKey(
    const HstoreHasKeyPayload(column: 'attributes', key: 'color'),
  )
  .rows();
```

### ltree

```dart
final rows = dataSource.context
  .table('ltree_items')
  .whereLtreeContains(
    const LtreeContainsPayload(column: 'path', path: 'Top.Science'),
  )
  .rows();
```

### citext

```dart
final rows = dataSource.context
  .table('citext_items')
  .whereCitextEquals(
    const CitextEqualsPayload(column: 'email', value: 'test@example.com'),
  )
  .rows();
```

### uuid-ossp

```dart
final rows = dataSource.context
  .table('citext_items')
  .selectUuidOsspV4(alias: 'uuid_v4')
  .limit(1)
  .rows();
```

### pgcrypto

```dart
final rows = dataSource.context
  .table('citext_items')
  .selectPgcryptoDigest(
    const PgcryptoDigestPayload(value: 'hello', algorithm: 'sha256'),
    alias: 'digest',
  )
  .limit(1)
  .rows();
```

### PostGIS topology

```dart
final rows = dataSource.context
  .table('topology_items')
  .selectPostgisTopologyCreate(
    const PostgisTopologyCreatePayload(name: 'ormed_topology', srid: 4326),
    alias: 'topology_id',
  )
  .limit(1)
  .rows();
```

### PostGIS raster

```dart
final rows = dataSource.context
  .table('raster_items')
  .selectPostgisRasterWidth(
    const PostgisRasterDimensionPayload(column: 'rast'),
    alias: 'width',
  )
  .limit(1)
  .rows();
```

## Docker Compose

PostGIS:

```
./tool/docker/postgis/docker-compose.yml
```

Default connection string:

```
postgres://postgres:postgres@localhost:65432/ormed_postgis
```

Postgres (contrib extensions):

```
./tool/docker/postgres/docker-compose.yml
```

Default connection string:

```
postgres://postgres:postgres@localhost:65431/ormed_extensions
```

pgvector:

```
./tool/docker/pgvector/docker-compose.yml
```

Default connection string:

```
postgres://postgres:postgres@localhost:65433/ormed_pgvector
```

Export before running tests:

```
export POSTGIS_URL=postgres://postgres:postgres@localhost:65432/ormed_postgis
export POSTGRES_EXT_URL=postgres://postgres:postgres@localhost:65431/ormed_extensions
export PGVECTOR_URL=postgres://postgres:postgres@localhost:65433/ormed_pgvector
```
