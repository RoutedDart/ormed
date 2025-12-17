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
