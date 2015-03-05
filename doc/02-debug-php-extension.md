Debugging PHP Extensions
========================

Using GDB
---------

GDB, or the GNU Project Debugger, allows you to debug a program while it is executing. GDB can start a program, stop it on specified conditions, examine the execution environment when the program is stopped and allow you to change things inside the running program itself.

### Configuring GDB

The .gdbinit script is provided with the PHP source distribution located under /home/vagrant/php-src. By copying this file to the home directory, gdb will always load this file when it starts.

```sh
$ copy ~/php-src/.gdbinit ~/.gdbinit
```

To optionally load gdb at runtime:

> (gdb) source /home/vagrant/php-src/.gdbinit

The .gdbinit script provides a number of commands within gdb that are helpful when debugging extensions.

To view the commands provided try the following:

```sh
$ gdb
```
> (gdb) help user-defined
