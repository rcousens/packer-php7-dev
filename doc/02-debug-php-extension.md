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

```
Breakpoint 1, php_do_pcre_match (execute_data=0x7ffff0214260, return_value=0x7ffff0214100, global=0) 
  at /home/vagrant/php-src/ext/pcre/php_pcre.c:549
```

Let's use the zbacktrace command to find out where we came from.

```
(gdb) zbacktrace
[0x7ffff0214260] preg_match("/^[hH]ello,\s/", "Hello,\40world.\40[*],\40this\40is\40\\40a\40string", reference) [internal function]
[0x7ffff0214030] (main) /home/vagrant/php-src/ext/pcre/tests/preg_match_basic.phpt:10 
```

The above output shows that we are inside the first assertion of our unit test trying to match the word Hello/hello at the start of a string against our subject "Hello, world. [4], this is \ a string".

Running next allows us to move line by line through the execution of the original source code. Enter next a few times until you reach a function invocation that looks like this:

```
(gdb) next
    php_pcre_match_impl(pce, subject->val, (int)subject->len, return_value, subpats, ...
```

In GDB, we can step inside any function call. The 'next' command by default steps over functions where as 'step' allows us to follow the execution path.

Let's step inside! For function calls that span multiple lines in the source file, you may have to call step a few times.

```
(gdb) step
...
(gdb) step
php_pcre_match_impl (pce=0x1a98b70, subject=0x7ffff02028b8 "Hello, world. [*], this is \\ 
    a string", subject_len=37, return_value=0x7ffff0214100, subpats=0x7ffff02010e8, global=0, 
    use_flags=0, flags=0, start_offset=0) 
  at /home/vagrant/php-src/ext/pcre/php_pcre.c:585
```

Now we are inside the lowest level of the extension that wraps about the PCRE library. Looking at the source for php_pcre.c, we see that php_do_pcre_match calls another function php_pcre_match_impl after parsing the arguments from the Zend VM. We know the string that's the subject for evaluation, let's see if we can use the argument subject to php_pcre_match_impl to catch it.

In GDB a break can take a conditional argument. Knowing that a string starting with the character 'H' is the subject for our unit tests, let's try and break on that condition. To do so we'll kill the current running program, delete the existing breakpoint and create a new conditional one.

```
(gdb) kill
Kill the program being debugged? (y or n) y
```

Delete the existing breakpoint:

```
(gdb) delete 1
```

Now let's set a conditional breakpoint in the lower level function we stepped into before:

```
(gdb) break php_pcre_match_impl if subject[0] == 'H'
(gdb) run
```

Success!

```
Breakpoint 2, php_pcre_match_impl (pce=0x1a98b70, subject=0x7ffff02028b8 "Hello, world. [*], 
    this is \\ a string", subject_len=37, return_value=0x7ffff0214100, subpats=0x7ffff02010e8, 
    global=0, use_flags=0, flags=0, start_offset=0)
  at /home/vagrant/php-src/ext/pcre/php_pcre.c:585
```

Let's have a look at what's happening inside this function and start execution line by line:

```
(gdb) info args
...
(gdb) info local
...
(gdb) next
...
```

The args output clearly shows the string we were looking for. Local shows the variables in scope for the current function. Now we can start moving through the code and find out how php_pcre_match_impl works. Looking at the source, we can see a call to a library function pcre_exec at line 688. Let's break there.

First we create a new breakpoint, continue execution, and then step inside the pcre_exec call.

```
(gdb) break 688
(gdb) continue
(gdb) step
```


Once we're done debugging the pcre_exec call, to return from the current function we can use 'finish' and look at the results being passed back through to the extension.

```
(gdb) finish
```

Now we're back from the call to count = pcre_exec(...), let's look at the result.

```
Run till exit from #0  php_pcre_exec (argument_re=0x1a98a00, extra_data=0x1a98a80, 
    subject=0x7ffff02028b8 "Hello, world. [*], this is \\ a string", length=37, 
    start_offset=0, options=0, offsets=0x7fffffffa8c0, offsetcount=3)
  at /home/vagrant/php-src/ext/pcre/pcrelib/pcre_exec.c:6355
  
0x00000000005860f5 in php_pcre_match_impl (pce=0x1a98b70, subject=0x7ffff02028b8 "Hello, 
    world. [*], this is \\ a string", subject_len=37, return_value=0x7ffff0214100, 
    subpats=0x7ffff02010e8, global=0, use_flags=0, flags=0, start_offset=0)
  at /home/vagrant/php-src/ext/pcre/php_pcre.c:688

688  count = pcre_exec(pce->re, extra, subject, (int)subject_len, (int)start_offset,
Value returned is $4 = 1
```

Excellent, so our library functino pcre_exec correctly found 1 match for the regular expression against the subject and returned the result to the local variable count in the php_pcre_match_impl function.


