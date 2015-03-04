Running PHP7 tests
==================

Using make
----------

```sh
$ make test;
```

To generate coverage:

```sh
$ make lcov;
```

Testing Extensions
------------------

```sh
$ make test TESTS=ext\<name>\tests
```

This command will take any valid glob for tests.
