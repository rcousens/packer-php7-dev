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
-------------------------

```sh
$ cd ~/php-src && mkdir custom-build && cd custom-build && ~/php-src/configure --my-flags
```
