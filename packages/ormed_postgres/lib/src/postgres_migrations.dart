import 'package:ormed/migrations.dart';

extension PostgresTableBlueprintExtensions on TableBlueprint {
  ColumnBuilder inet(
    String name, {
    ColumnMutation mutation = ColumnMutation.add,
  }) {
    return column(name, const ColumnType.custom('inet'), mutation: mutation);
  }

  ColumnBuilder cidr(
    String name, {
    ColumnMutation mutation = ColumnMutation.add,
  }) {
    return column(name, const ColumnType.custom('cidr'), mutation: mutation);
  }

  ColumnBuilder macaddr(
    String name, {
    ColumnMutation mutation = ColumnMutation.add,
  }) {
    return column(name, const ColumnType.custom('macaddr'), mutation: mutation);
  }

  ColumnBuilder macaddr8(
    String name, {
    ColumnMutation mutation = ColumnMutation.add,
  }) {
    return column(
      name,
      const ColumnType.custom('macaddr8'),
      mutation: mutation,
    );
  }

  ColumnBuilder tsvector(
    String name, {
    ColumnMutation mutation = ColumnMutation.add,
  }) {
    return column(
      name,
      const ColumnType.custom('tsvector'),
      mutation: mutation,
    );
  }

  ColumnBuilder tsquery(
    String name, {
    ColumnMutation mutation = ColumnMutation.add,
  }) {
    return column(name, const ColumnType.custom('tsquery'), mutation: mutation);
  }

  ColumnBuilder interval(
    String name, {
    ColumnMutation mutation = ColumnMutation.add,
  }) {
    return column(
      name,
      const ColumnType.custom('interval'),
      mutation: mutation,
    );
  }

  ColumnBuilder int4range(
    String name, {
    ColumnMutation mutation = ColumnMutation.add,
  }) {
    return column(
      name,
      const ColumnType.custom('int4range'),
      mutation: mutation,
    );
  }

  ColumnBuilder int8range(
    String name, {
    ColumnMutation mutation = ColumnMutation.add,
  }) {
    return column(
      name,
      const ColumnType.custom('int8range'),
      mutation: mutation,
    );
  }

  ColumnBuilder numrange(
    String name, {
    ColumnMutation mutation = ColumnMutation.add,
  }) {
    return column(
      name,
      const ColumnType.custom('numrange'),
      mutation: mutation,
    );
  }

  ColumnBuilder daterange(
    String name, {
    ColumnMutation mutation = ColumnMutation.add,
  }) {
    return column(
      name,
      const ColumnType.custom('daterange'),
      mutation: mutation,
    );
  }

  ColumnBuilder tsrange(
    String name, {
    ColumnMutation mutation = ColumnMutation.add,
  }) {
    return column(name, const ColumnType.custom('tsrange'), mutation: mutation);
  }

  ColumnBuilder tstzrange(
    String name, {
    ColumnMutation mutation = ColumnMutation.add,
  }) {
    return column(
      name,
      const ColumnType.custom('tstzrange'),
      mutation: mutation,
    );
  }

  ColumnBuilder bit(
    String name, {
    ColumnMutation mutation = ColumnMutation.add,
    int? length,
  }) {
    final sql = length == null ? 'bit' : 'bit($length)';
    return column(name, ColumnType.custom(sql), mutation: mutation);
  }

  ColumnBuilder varbit(
    String name, {
    ColumnMutation mutation = ColumnMutation.add,
    int? length,
  }) {
    final sql = length == null ? 'varbit' : 'varbit($length)';
    return column(name, ColumnType.custom(sql), mutation: mutation);
  }

  ColumnBuilder timetz(
    String name, {
    ColumnMutation mutation = ColumnMutation.add,
    int? precision,
  }) {
    final sql = precision == null ? 'timetz' : 'timetz($precision)';
    return column(name, ColumnType.custom(sql), mutation: mutation);
  }

  ColumnBuilder money(
    String name, {
    ColumnMutation mutation = ColumnMutation.add,
  }) {
    return column(name, const ColumnType.custom('money'), mutation: mutation);
  }

  ColumnBuilder xml(
    String name, {
    ColumnMutation mutation = ColumnMutation.add,
  }) {
    return column(name, const ColumnType.custom('xml'), mutation: mutation);
  }

  ColumnBuilder pgLsn(
    String name, {
    ColumnMutation mutation = ColumnMutation.add,
  }) {
    return column(name, const ColumnType.custom('pg_lsn'), mutation: mutation);
  }

  ColumnBuilder pgSnapshot(
    String name, {
    ColumnMutation mutation = ColumnMutation.add,
  }) {
    return column(
      name,
      const ColumnType.custom('pg_snapshot'),
      mutation: mutation,
    );
  }

  ColumnBuilder txidSnapshot(
    String name, {
    ColumnMutation mutation = ColumnMutation.add,
  }) {
    return column(
      name,
      const ColumnType.custom('txid_snapshot'),
      mutation: mutation,
    );
  }

  ColumnBuilder line(
    String name, {
    ColumnMutation mutation = ColumnMutation.add,
  }) {
    return column(name, const ColumnType.custom('line'), mutation: mutation);
  }

  ColumnBuilder lseg(
    String name, {
    ColumnMutation mutation = ColumnMutation.add,
  }) {
    return column(name, const ColumnType.custom('lseg'), mutation: mutation);
  }

  ColumnBuilder box(
    String name, {
    ColumnMutation mutation = ColumnMutation.add,
  }) {
    return column(name, const ColumnType.custom('box'), mutation: mutation);
  }

  ColumnBuilder path(
    String name, {
    ColumnMutation mutation = ColumnMutation.add,
  }) {
    return column(name, const ColumnType.custom('path'), mutation: mutation);
  }

  ColumnBuilder circle(
    String name, {
    ColumnMutation mutation = ColumnMutation.add,
  }) {
    return column(name, const ColumnType.custom('circle'), mutation: mutation);
  }

  ColumnBuilder pgArray(
    String name,
    String elementType, {
    ColumnMutation mutation = ColumnMutation.add,
  }) {
    return column(
      name,
      ColumnType.custom('${elementType.trim()}[]'),
      mutation: mutation,
    );
  }

  ColumnBuilder uuidArray(
    String name, {
    ColumnMutation mutation = ColumnMutation.add,
  }) => pgArray(name, 'uuid', mutation: mutation);

  ColumnBuilder textArray(
    String name, {
    ColumnMutation mutation = ColumnMutation.add,
  }) => pgArray(name, 'text', mutation: mutation);

  ColumnBuilder intArray(
    String name, {
    ColumnMutation mutation = ColumnMutation.add,
  }) => pgArray(name, 'integer', mutation: mutation);

  ColumnBuilder citext(
    String name, {
    ColumnMutation mutation = ColumnMutation.add,
  }) {
    return column(name, const ColumnType.custom('citext'), mutation: mutation);
  }

  ColumnBuilder hstore(
    String name, {
    ColumnMutation mutation = ColumnMutation.add,
  }) {
    return column(name, const ColumnType.custom('hstore'), mutation: mutation);
  }

  ColumnBuilder ltree(
    String name, {
    ColumnMutation mutation = ColumnMutation.add,
  }) {
    return column(name, const ColumnType.custom('ltree'), mutation: mutation);
  }

  ColumnBuilder pgVector(
    String name, {
    ColumnMutation mutation = ColumnMutation.add,
    int? dimensions,
  }) {
    return vector(name, mutation: mutation, dimensions: dimensions);
  }
}

extension PostgresSchemaBuilderExtensions on SchemaBuilder {
  void enableExtension(String name, {bool ifNotExists = true}) {
    final statement = ifNotExists
        ? 'CREATE EXTENSION IF NOT EXISTS "$name"'
        : 'CREATE EXTENSION "$name"';
    raw(statement);
  }
}
