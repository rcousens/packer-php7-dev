Configure
=========

```sh
$ ./configure
```

PHP extensions can be bundled into the core executable (prevents wrong execution order, failed dependencies etc.) or compiled as shared objects to be included at runtime through php.ini.

Enabling and Disabling Extensions
---------------------------------

Defaults are determined by the config.[m4|w32] files that can be found in ext/<name> directories.

> --enable-foo [typically disabled by default]

> --disable-foo [typically enabled by default]

> --with-foo [requires external lib, typically disabled by default]

> --without-foo [requires external lib, typically enabled by default]

Extensions As Shared Objects
----------------------------

Some support the shared option

> --enable-foo=shared

> --with-foo=shared,/path/to/lib

Build Directories and Configure
-------------------------------

```sh
$ cd ~/php-src && mkdir custom-build && cd custom-build && ~/php-src/configure --my-flags
```

Compiling
=========

Overview
--------

```sh
$ ./buildconfig
$ ./configure --flags
$ make
```

Flags Of Interest
-----------------

#### Debug

Reports memory leaks through cleaning up of lost memory blocks after end of script execution and includes debugging symbols for GDB.

````
--enable-debug
````

#### GCOV

Requires lcov and genhtml available on the path and gcov installed. See [lcov state files](../salt/roots/salt/dev/lcov/init.sls). Enables code coverage analysis and report generation.

````
--enable-gcov
````

#### ZTS Maintainer

Enables the zend thread safety layer, slower but useful for debugging

````
--enable-maintainer-zts
````

Thanks to [@derickr](https://github.com/derickr) and [@johannes](https://github.com/johannes) for their patience and tutelage!
