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

After a few moments, you should see:

> Breakpoint 1, php_do_pcre_match (execute_data=0x7ffff0216080, return_value=0x7ffff02159e0, global=0)
> at /home/vagrant/php-src/ext/pcre/php_pcre.c:549

Let's use the zbacktrace command to find out where we came from.

```
(gdb) zbacktrace
[0x7ffff0216080] preg_match("/\.phpt$/", "/home/vagrant/php-src/ext/pcre/tests/preg_match_basic.phpt") [internal function]
[0x7ffff0214030] (main) /home/vagrant/php-src/run-tests.php:773 
```

The above output shows that we are yet to reach our unit test, as preg_match is used by the run-tests.php script to locate .phpt files. Let's continue execution:

```
(gdb) continue
...
(gdb) zbacktrace
```

More of the same. Let's try another approach, looking at the source for php_pcre.c, we see that php_do_pcre_match calls another function php_pcre_match_impl after parsing the arguments from the zend engine. We know the string that's the subject for evaluation, let's see if we can use the argument subject to php_pcre_match_impl to catch it.

We'll delete the existing breakpoint first:

```
(gdb) delete 1
```

Now let's set a conditional breakpoint in the second function:

```
(gdb) break php_pcre_match_impl if subject == "Hello, world. [*], this is \ a string"
(gdb) continue
```

Success!

> Breakpoint 2, php_pcre_match_impl (pce=0x1a98b90, subject=0x1a98f00 "Hello, world. [*], this is  a string",
> subject_len=50, return_value=0x7ffff0216cb0, subpats=0x7ffff0201dd0, global=0, use_flags=0, flags=0,
> start_offset=0) at /home/vagrant/php-src/ext/pcre/php_pcre.c:585

Let's have a look at what's happening inside this function and start execution line by line:

```
(gdb) info args
...
(gdb) info local
...
(gdb) next
...
```

The args output clearly shows the string we were looking for. Local shows the variables in scope for the current function. The next command allows us to execute the next line of source code. Now we can start stepping through the code and find out how php_pcre_match_impl works. Looking at the source, we can see a call to a library function pcre_exec at line 688. Let's break there.

```
(gdb) break 688
(gdb) continue
(gdb) step
```

The step command lets us step inside the function call to pcre_exec and see what it does.

Using next and step, you can proceed to the next line of code, or step inside a function call. To exit the current function and see the returned results from pcre_exec, we can use finish.

```
(gdb) finish
```

Now we're back from the call to count = pcre_exec(...), let's look at the result.





