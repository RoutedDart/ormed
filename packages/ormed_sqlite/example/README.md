# ormed_sqlite examples

## Native example

Run the package example directly from `packages/ormed_sqlite/`:

```bash
dart run example/main.dart
```

## Web example

The browser example lives in [`web/`](./web) and uses the unified
`package:ormed_sqlite` API.

1. Download the WebAssembly module:

```bash
dart run example/tool/fetch_sqlite3_wasm.dart
```

2. Compile the app and worker:

```bash
dart compile js example/web/main.dart -O4 -o example/web/main.js
dart compile js example/web/worker.dart -O4 -o example/web/worker.js
```

3. Serve the `example/` directory and open `/web/`:

```bash
python3 -m http.server --directory example 8080
```
