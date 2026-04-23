import 'dart:js_interop';

import 'package:sqlite3/wasm.dart';
import 'package:sqlite3_web/sqlite3_web.dart';

void runSqliteWebWorker() {
  WebSqlite.workerEntrypoint(
    controller: const _DefaultOrmedSqliteWebController(),
  );
}

final class _DefaultOrmedSqliteWebController extends DatabaseController {
  const _DefaultOrmedSqliteWebController();

  @override
  Future<WorkerDatabase> openDatabase(
    WasmSqlite3 sqlite3,
    String path,
    String vfs,
    JSAny? additionalData,
  ) async {
    return _DefaultOrmedSqliteWebDatabase(sqlite3.open(path, vfs: vfs));
  }

  @override
  Future<JSAny?> handleCustomRequest(
    ClientConnection connection,
    CustomClientRequest request,
  ) {
    throw UnimplementedError();
  }
}

final class _DefaultOrmedSqliteWebDatabase extends WorkerDatabase {
  _DefaultOrmedSqliteWebDatabase(this.database);

  @override
  final CommonDatabase database;

  @override
  Future<JSAny?> handleCustomRequest(
    ClientConnection connection,
    CustomClientDatabaseRequest request,
  ) {
    throw UnimplementedError();
  }
}
