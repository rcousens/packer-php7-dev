Debugging PHP Extensions
========================

The following tutorial is conducted from within the /home/vagrant/php-src directory.

Using GDB
---------

GDB, or the GNU Project Debugger, allows you to debug a program while it is executing. GDB can start a program, stop it on specified conditions, examine the execution environment when the program is stopped and allow you to change things inside the running program itself.

[GDB Reference Documentation](https://sourceware.org/gdb/current/onlinedocs/gdb/)

#### Configuring GDB

Let's get started by changing to the php-src directory

```sh
$ cd ~/php-src
```

The .gdbinit script is provided with the PHP source distribution. By copying this file to the home directory, gdb will always load this file when it starts.

```sh
$ copy .gdbinit ~
```

Alternatively you can load the script into gdb at runtime:

```sh
$ gdb
...
(gdb) source /home/vagrant/php-src/.gdbinit
```

The .gdbinit script provides a number of commands within gdb that are helpful when debugging extensions.

To view the commands provided try the following:

```sh
$ gdb
...
(gdb) help user-defined
```

Of particular interest is zbacktrace which enables one to backtrace from C to PHP.

#### Debugging the PCRE extension

To familiarise ourselves with GDB and its commands available for debugging we will step through a PHP PCRE extension test.

##### Setup the PHP test executable

The run-tests.php script relies on an environment variable TEST_PHP_EXECUTABLE to be defined and set to the appropriate PHP CLI bin. 

Let's configure that now:

```sh
$ export TEST_PHP_EXECUTABLE=sapi/cli/php
```

##### Loading GDB

Now let's load gdb and tell it the program we intend to execute:

```sh
$ gdb --args sapi/cli/php run-tests.php ext/pcre/tests/preg_match_basic.phpt
```

##### Breaking in GDB from PHP Function calls

The PHP function we intend to examine is preg_match() and is defined in the ext/pcre/php_pcre.c file as a static PHP_FUNCTION wrapper around another static function php_do_pcre_match.

Our test file, ext/pcre/tests/preg_match_basic.phpt evaluates a number of regular expressions against a string and extracts matches into a variable. The .phpt file defines a PHP script to run as input and the corresponding output data that it expects to see from a successful test.

```php
$string = 'Hello, world. [*], this is \ a string';
var_dump(preg_match('/^[hH]ello,\s/', $string, $match1)); //finds "Hello, "
var_dump($match1);
```

Running the above should produce:

```php
int(1)
array(1) {
  [0]=>
  string(7) "Hello, "
}
```

Where int(1) signifies preg_match returning true for a match, with an array(1) of matched strings, in this case there is only one match, "Hello, ".

Knowing that php_do_pcre_match is called, let's tell gdb we would like to break on invocation of php_do_pcre_match and then run the test.

```sh
(gdb) break php_do_pcre_match
(gdb) run

```

