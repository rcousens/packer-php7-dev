Running PHP7 tests
==================

Using make
----------

### From /home/vagrant/php-src:

```sh
$ make test;
```

Substitute test with lcov to run tests and generate an lcov_html output directory with HTML formatted coverage results.

```sh
$ make lcov;
```

Using php cli
-------------

### From /home/vagrant/php-src:

```sh
$ TEST_PHP_EXECUTABLE=sapi/cli/php sapi/cli/php [-c optional.ini] run-tests.php
```

Testing Extensions
------------------

```sh
$ make test TESTS=ext/<name>
```
OR

```sh
$ TEST_PHP_EXECUTABLE=sapi/cli/php sapi/cli/php [-c optional.ini] run-tests.php ext/<name>
```

This command will take any extension name or alternatively a valid glob for tests e.g. ext/pcre/tests/*.phpt. For finer grained testing you can pass in a specific .phpt file e.g. ext/pcre/tests/001.phpt



