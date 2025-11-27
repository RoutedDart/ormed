# orm_driver_tests

Shared, driver-agnostic integration tests for the routed ORM. These suites
assert baseline query, mutation, and transaction behaviors that every driver
must satisfy. Individual driver packages pull in this package as a
`dev_dependency`, supply their own test harness, and run the shared suites.
