library;

import 'sqlite_web_worker_stub.dart'
    if (dart.library.js_interop) 'sqlite_web_worker_web.dart'
    as impl;

void runSqliteWebWorker() => impl.runSqliteWebWorker();
