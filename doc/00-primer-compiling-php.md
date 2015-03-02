Configure
---------

PHP extensions can be bundled into the core executable (prevents wrong execution order, failed dependencies etc.) or compiled as shared objects to be included at runtime through php.ini.

General Flags
=============

> --enable-foo = disabled by default

> --disable-foo = enabled by default

> --with-foo = requires external lib, disabled by default

> --without-foo = requires external lib, enabled by default

Extensions
==========

Some support the shared option

> --enable-foo=shared

> --with-foo=shared,/path/to/lib
