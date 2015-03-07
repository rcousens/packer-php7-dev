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

##### PHP Tests Wrapper

The run-tests.php script locates test files and then creates a unique shell script to execute each one in a pristine context. To avoid the complexity and overhead of dealing with GDB and fork/exec, we will run our test directly and bypass the run-tests.php script.

##### Loading GDB

Now let's load gdb and tell it we intend to run the phpt test file by executing the PHP CLI binary with an argument to its location:

```sh
$ gdb --args sapi/cli/php ext/pcre/tests/preg_match_basic.phpt
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

After a few moments, you should see something similar to:

> Breakpoint 1, php_do_pcre_match (execute_data=0x7ffff0214260, return_value=0x7ffff0214100, global=0) at
> /home/vagrant/php-src/ext/pcre/php_pcre.c:549

Let's use the zbacktrace command to find out where we came from.

```
(gdb) zbacktrace
[0x7ffff0214260] preg_match("/^[hH]ello,\s/", "Hello,\40world.\40[*],\40this\40is\40\\40a\40string", reference) [internal function]
[0x7ffff0214030] (main) /home/vagrant/php-src/ext/pcre/tests/preg_match_basic.phpt:10 
```

The above output shows that we are inside the first assertion of our unit test trying to match the word Hello/hello at the start of a string against our subject "Hello, world. [4], this is \ a string".

Let's see what this function does:

```
(gdb) next
...
(gdb) next
...
```

Running next allows us to move line by line through the execution of the original source code. After a few next calls, we reach a function invocation that looks like this:

```
(gdb) next
        php_pcre_match_impl(pce, subject->val, (int)subject->len, return_value, subpats, ...
```

In GDB, we can step inside any function call. The 'next' command by default steps over where as 'step' allows us to follow the execution path.

Let's step inside! For function calls that span multiple lines in the source file, you may have to call step a few times.

```
(gdb) step
...
(gdb) step
php_pcre_match_impl (pce=0x1a98b70, subject=0x7ffff02028b8 "Hello, world. [*], this is \\ a string", subject_len=37, return_value=0x7ffff0214100, subpats=0x7ffff02010e8, global=0, use_flags=0, flags=0, start_offset=0) at /home/vagrant/php-src/ext/pcre/php_pcre.c:585
```

Now we are inside the lowest level of the extension that wraps about the PCRE library. Looking at the source for php_pcre.c, we see that php_do_pcre_match calls another function php_pcre_match_impl after parsing the arguments from the Zend VM. We know the string that's the subject for evaluation, let's see if we can use the argument subject to php_pcre_match_impl to catch it.

Let's try and find a way to break there conditionally, based on the arugments being passed in for our first unit tests. We'll kill the current running program, and try a new breakpoint.

```
(gdb) kill
Kill the program being debugged? (y or n) y
```

We'll delete the existing breakpoint first:

```
(gdb) delete 1
```

Now let's set a conditional breakpoint in the lower level function we stepped into before:

```
(gdb) break php_pcre_match_impl if subject[0] == 'H'
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





