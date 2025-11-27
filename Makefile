# Helper targets to run the MySQL/MariaDB driver suites locally.

REPO_ROOT := $(abspath .)
# Packages with self-contained `dart test` suites.
ORM_PACKAGES := ormed ormed_sqlite orm_cli
MARIADB_COMPOSE := $(REPO_ROOT)/packages/ormed_mysql/docker-compose.yml
MYSQL_COMPOSE := $(REPO_ROOT)/packages/ormed_mysql/docker-compose.mysql.yml
POSTGRES_COMPOSE := $(REPO_ROOT)/packages/ormed_postgres/docker-compose.yml
MARIADB_URL := mariadb://root:secret@localhost:6604/orm_test
MYSQL_URL := mysql://root:secret@localhost:6605/orm_test
POSTGRES_URL := postgres://postgres:postgres@localhost:6543/orm_test

.PHONY: test-mariadb test-mysql test-postgres test-all \
    test-orm-core test-orm-driver-tests test-ormed-sqlite test-orm-cli \
    test-orm-mysql test-orm-postgres test-packages \
    mariadb-up mariadb-down mysql-up mysql-down postgres-up postgres-down

mariadb-up:
	docker compose -f $(MARIADB_COMPOSE) up -d

mariadb-down:
	docker compose -f $(MARIADB_COMPOSE) down -v

mysql-up:
	docker compose -f $(MYSQL_COMPOSE) up -d

mysql-down:
	docker compose -f $(MYSQL_COMPOSE) down -v

postgres-up:
	docker compose -f $(POSTGRES_COMPOSE) up -d

postgres-down:
	docker compose -f $(POSTGRES_COMPOSE) down -v

test-orm-core:
	dart test packages/ormed

test-orm-driver-tests:
	dart test packages/driver_tests

test-ormed-sqlite:
	dart test packages/ormed_sqlite

test-orm-cli:
	dart test packages/orm_cli

test-orm-mysql:
	dart test packages/ormed_mysql

test-orm-postgres:
	dart test packages/ormed_postgres

test-packages:
	@set -e; \
	for pkg in $(ORM_PACKAGES); do \
	  if [ -d packages/$$pkg/test ]; then \
	    echo "\n===> Running tests for $$pkg"; \
	    dart test packages/$$pkg || exit $$?; \
	  else \
	    echo "\n===> Skipping $$pkg (no test/ directory)"; \
	  fi; \
	done

# Runs the ormed_mysql suite against the MariaDB container.
test-mariadb:
	@set -e; \
	docker compose -f $(MARIADB_COMPOSE) up -d; \
	sleep 5; \
	MARIADB_URL=$(MARIADB_URL) dart test packages/ormed_mysql/test/mariadb_driver_shared_test.dart -r expanded; \
	status=$$?; \
	docker compose -f $(MARIADB_COMPOSE) down -v; \
	exit $$status

# Runs the ormed_mysql suite against the MySQL container.
test-mysql:
	@set -e; \
	docker compose -f $(MYSQL_COMPOSE) up -d; \
	sleep 5; \
	MYSQL_URL=$(MYSQL_URL) dart test packages/ormed_mysql/test/mysql_driver_shared_test.dart -r expanded; \
	status=$$?; \
	docker compose -f $(MYSQL_COMPOSE) down -v; \
	exit $$status

# Runs the ormed_postgres suite against a local Postgres container.
test-postgres:
	@set -e; \
	docker compose -f $(POSTGRES_COMPOSE) up -d; \
	sleep 5; \
	POSTGRES_URL=$(POSTGRES_URL) dart test packages/ormed_postgres -r expanded; \
	status=$$?; \
	docker compose -f $(POSTGRES_COMPOSE) down -v; \
	exit $$status

# Convenience target that runs every ORM package test suite.
test-all: test-packages test-postgres test-mariadb test-mysql
