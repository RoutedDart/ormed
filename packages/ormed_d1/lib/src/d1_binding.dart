import 'dart:typed_data';

/// Decodes a row returned by a D1 binding.
typedef D1RowDecoder<T> = T Function(Map<String, Object?> row);

/// Metadata returned by a D1 statement.
final class D1Meta {
  /// Creates D1 metadata.
  const D1Meta({
    this.duration,
    this.rowsRead,
    this.rowsWritten,
    this.changes,
    this.changedDb,
    this.sizeAfter,
    this.lastRowId,
    this.servedBy,
    this.servedByColo,
    this.servedByPrimary,
    this.servedByRegion,
    this.servedByLocation,
    this.bookmark,
  });

  final num? duration;
  final int? rowsRead;
  final int? rowsWritten;
  final int? changes;
  final bool? changedDb;
  final int? sizeAfter;
  final Object? lastRowId;
  final String? servedBy;
  final String? servedByColo;
  final bool? servedByPrimary;
  final String? servedByRegion;
  final String? servedByLocation;
  final String? bookmark;
}

/// A result returned by a D1 binding operation.
final class D1Result<T> {
  /// Creates a D1 result.
  const D1Result({
    required this.success,
    this.results = const <Never>[],
    this.meta,
    this.error,
  });

  final bool success;
  final List<T> results;
  final D1Meta? meta;
  final Object? error;
}

/// The aggregate returned by a D1 `exec` operation.
final class D1ExecResult {
  /// Creates a D1 exec result.
  const D1ExecResult({required this.count, required this.duration});

  final int count;
  final num duration;
}

/// The host-neutral Cloudflare D1 binding contract.
abstract interface class D1DatabaseBinding {
  /// Prepares a SQL statement.
  D1PreparedStatementBinding prepare(String query);

  /// Runs statements as one atomic D1 batch.
  Future<List<D1Result<T>>> batch<T>(
    Iterable<D1PreparedStatementBinding> statements, {
    D1RowDecoder<T>? decode,
  });

  /// Executes a raw SQL script using the binding's `exec` operation.
  Future<D1ExecResult> exec(String query);

  /// Dumps the database.
  Future<Uint8List> dump();

  /// Creates a sequential-consistency session.
  D1DatabaseSessionBinding withSession({String? bookmark});
}

/// A prepared SQL statement from a D1 binding.
abstract interface class D1PreparedStatementBinding {
  /// Binds values to this statement.
  D1PreparedStatementBinding bind([Iterable<Object?> values]);

  /// Returns all rows.
  Future<D1Result<T>> all<T>({D1RowDecoder<T>? decode});

  /// Returns the first row or value.
  Future<T?> first<T>({String? column, D1RowDecoder<T>? decode});

  /// Executes a mutation or a statement with `RETURNING` rows.
  Future<D1Result<T>> run<T>({D1RowDecoder<T>? decode});

  /// Returns rows without result metadata.
  Future<List<T>> raw<T>({D1RowDecoder<T>? decode});
}

/// A sequential-consistency D1 session.
abstract interface class D1DatabaseSessionBinding {
  /// Prepares a statement in this session.
  D1PreparedStatementBinding prepare(String query);

  /// Runs statements as one atomic D1 batch in this session.
  Future<List<D1Result<T>>> batch<T>(
    Iterable<D1PreparedStatementBinding> statements, {
    D1RowDecoder<T>? decode,
  });

  /// Returns the session bookmark.
  Future<String?> getBookmark();
}
