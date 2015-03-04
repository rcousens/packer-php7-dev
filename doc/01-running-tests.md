Running PHP7 tests
==================

Using make
----------

```sh
$ make test;
```

Substitute test with lcov to run tests and generate an lcov_html output directory with HTML formatted coverage results.

```sh
$ make lcov;
```

Testing Extensions
------------------

```sh
$ make test TESTS=ext\<name>\tests
```

This command will take any valid glob for tests.
