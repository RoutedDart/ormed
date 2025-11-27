## 0.1.0-dev

- Initial release of the MySQL/MariaDB driver adapter powered by
  `mysql_client_plus`. Implements `DriverAdapter` + `SchemaDriver`, provides
  JSON/bool codecs, Docker helpers, and reuses the shared driver conformance
  suites with dedicated `MySqlDriverAdapter` + `MariaDbDriverAdapter` entry
  points.
