import 'dart:typed_data';

import 'package:ormed_d1/ormed_d1.dart';
import 'package:test/test.dart';

final class _FakeDatabase implements D1DatabaseBinding {
  final List<String> preparedSql = [];

  @override
  Future<List<D1Result<T>>> batch<T>(
    Iterable<D1PreparedStatementBinding> statements, {
    D1RowDecoder<T>? decode,
  }) async {
    return [
      for (final statement in statements)
        await statement.run<T>(decode: decode),
    ];
  }

  @override
  Future<Uint8List> dump() async => Uint8List.fromList(const [1, 2, 3]);

  @override
  Future<D1ExecResult> exec(String query) async {
    return const D1ExecResult(count: 1, duration: 0);
  }

  @override
  D1PreparedStatementBinding prepare(String query) {
    preparedSql.add(query);
    return _FakeStatement(query);
  }

  @override
  D1DatabaseSessionBinding withSession({String? bookmark}) {
    return _FakeSession(this, bookmark);
  }
}

final class _FakeStatement implements D1PreparedStatementBinding {
  _FakeStatement(this.sql, [this.parameters = const []]);

  final String sql;
  final List<Object?> parameters;

  Map<String, Object?> get row => {
    'sql': sql,
    'parameter_count': parameters.length,
  };

  @override
  Future<D1Result<T>> all<T>({D1RowDecoder<T>? decode}) async {
    final value = decode == null ? row as T : decode(row);
    return D1Result<T>(
      success: true,
      results: [value],
      meta: const D1Meta(rowsRead: 1),
    );
  }

  @override
  D1PreparedStatementBinding bind([Iterable<Object?> values = const []]) {
    return _FakeStatement(sql, List<Object?>.from(values));
  }

  @override
  Future<T?> first<T>({String? column, D1RowDecoder<T>? decode}) async {
    final result = await all<T>(decode: decode);
    return result.results.first;
  }

  @override
  Future<List<T>> raw<T>({D1RowDecoder<T>? decode}) async {
    final result = await all<T>(decode: decode);
    return result.results;
  }

  @override
  Future<D1Result<T>> run<T>({D1RowDecoder<T>? decode}) =>
      all<T>(decode: decode);
}

final class _FakeSession implements D1DatabaseSessionBinding {
  _FakeSession(this.database, this.bookmark);

  final _FakeDatabase database;
  final String? bookmark;

  @override
  Future<List<D1Result<T>>> batch<T>(
    Iterable<D1PreparedStatementBinding> statements, {
    D1RowDecoder<T>? decode,
  }) {
    return database.batch(statements, decode: decode);
  }

  @override
  D1PreparedStatementBinding prepare(String query) => database.prepare(query);

  @override
  Future<String?> getBookmark() async => bookmark;
}

void main() {
  test('binding transport maps query, execute, and atomic batch', () async {
    final database = _FakeDatabase();
    final transport = D1BindingTransport(database);

    final query = await transport.query('SELECT ?', [1]);
    final execute = await transport.execute('UPDATE users SET name = ?', [
      'Ada',
    ]);
    final batch = await transport.batch(const [
      D1Statement(
        sql: 'INSERT INTO users (name) VALUES (?)',
        parameters: ['Ada'],
      ),
      D1Statement(
        sql: 'INSERT INTO users (name) VALUES (?)',
        parameters: ['Grace'],
      ),
    ]);

    expect(query.rows.single['sql'], 'SELECT ?');
    expect(query.meta['rows_read'], 1);
    expect(execute.rows.single['parameter_count'], 1);
    expect(batch, hasLength(2));
    expect(database.preparedSql, hasLength(4));
  });

  test('binding transport exposes binding failures', () async {
    final transport = D1BindingTransport(_FailingDatabase());

    expect(transport.query('SELECT 1'), throwsA(isA<D1RequestException>()));
  });
}

final class _FailingDatabase implements D1DatabaseBinding {
  @override
  Future<List<D1Result<T>>> batch<T>(
    Iterable<D1PreparedStatementBinding> statements, {
    D1RowDecoder<T>? decode,
  }) async => throw UnimplementedError();

  @override
  Future<Uint8List> dump() async => Uint8List(0);

  @override
  Future<D1ExecResult> exec(String query) async =>
      const D1ExecResult(count: 0, duration: 0);

  @override
  D1PreparedStatementBinding prepare(String query) => _FailingStatement();

  @override
  D1DatabaseSessionBinding withSession({String? bookmark}) =>
      throw UnimplementedError();
}

final class _FailingStatement implements D1PreparedStatementBinding {
  @override
  Future<D1Result<T>> all<T>({D1RowDecoder<T>? decode}) async {
    return D1Result<T>(success: false, error: 'bad query');
  }

  @override
  D1PreparedStatementBinding bind([Iterable<Object?> values = const []]) =>
      this;

  @override
  Future<T?> first<T>({String? column, D1RowDecoder<T>? decode}) async => null;

  @override
  Future<List<T>> raw<T>({D1RowDecoder<T>? decode}) async => const [];

  @override
  Future<D1Result<T>> run<T>({D1RowDecoder<T>? decode}) =>
      all<T>(decode: decode);
}
