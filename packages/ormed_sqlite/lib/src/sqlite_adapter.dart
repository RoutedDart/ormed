library;

export 'sqlite_adapter_native.dart'
    if (dart.library.js_interop) 'sqlite_adapter_web.dart';
