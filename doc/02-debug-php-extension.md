Debugging PHP Extensions
========================

The following tutorial is conducted from within the /home/vagrant/php-src directory.

Using GDB
---------

GDB, or the GNU Project Debugger, allows you to debug a program while it is executing. GDB can start a program, stop it on specified conditions, examine the execution environment when the program is stopped and allow you to change things inside the running program itself.

[GDB Reference Documentation](https://sourceware.org/gdb/current/onlinedocs/gdb/)

### Configuring GDB

Let's get started by changing to the php-src directory

```sh
$ cd ~/php-src
```

The .gdbinit script is provided with the PHP source distribution. By copying this file to the home directory, gdb will always load this file when it starts.

```sh
$ copy .gdbinit ~
```

Alternatively you can load the script into gdb at runtime:

```
(gdb) source /home/vagrant/php-src/.gdbinit
```

The .gdbinit script provides a number of commands within gdb that are helpful when debugging extensions.

To view the available commands once the .gdbinit script is loaded provided try the following:

```
(gdb) help user-defined
```

Of particular interest is zbacktrace which enables one to backtrace from C to PHP.

### Debugging a PCRE extension

To familiarise ourselves with GDB and its commands available for debugging we will step through a PHP PCRE extension test.

#### PHP Tests Wrapper

The run-tests.php script locates test files and then creates a unique shell script to execute each one in a pristine context. To avoid the complexity and overhead of dealing with GDB and fork/exec, we will run our test directly and bypass the run-tests.php script.

#### Loading GDB

Now let's load gdb and tell it we intend to run the phpt test file by executing the PHP CLI binary with an argument to its location:

```sh
$ gdb --args sapi/cli/php ext/pcre/tests/preg_match_basic.phpt
```

#### PHP Function calls

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

TODO: more info on breakpoint formats.

#### Setting Breakpoints

```
(gdb) break php_do_pcre_match
(gdb) run

```

After a few moments, you should see something similar to:

```
Breakpoint 1, php_do_pcre_match (execute_data=0x7ffff0214260, return_value=0x7ffff0214100, 
    global=0) 
  at /home/vagrant/php-src/ext/pcre/php_pcre.c:549
```

Let's use the zbacktrace command to find out where we came from.

```
(gdb) zbacktrace
[0x7ffff0214260] preg_match("/^[hH]ello,\s/", "Hello,\40world.\40[*],\40this\40is\40\\40
    a\40string", reference) [internal function]
[0x7ffff0214030] (main) /home/vagrant/php-src/ext/pcre/tests/preg_match_basic.phpt:10 
```

The above output shows that we are inside the the function that generates the output that will be used as a comparison for the first assertion of our unit test. The first unit test in the preg_match_basic.phpt file tries to find matches based on the regex "/^[hH]ello,\s/" against our subject string "Hello, world. [4], this is \ a string".

#### Program Execution Flow

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

#### Stopping Execution and Breakpoints

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

#### Exploring Variables and Types


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

Excellent, so our library function pcre_exec correctly found 1 match for the regular expression against the subject and returned the result to the local variable count in the php_pcre_match_impl function.

Let's learn how unpack some internal zend engine data types to look at the results being returned back to PHP. First, let's finish the current php_pcre_match_impl function and get back to our entry point, php_do_pcre_match.

```
(gdb) finish
Run till exit from #0  php_pcre_match_impl (pce=0x1a98b70, subject=0x7ffff02028b8 "Hello, 
    world. [*], this is \\ a string", subject_len=37, return_value=0x7ffff0214100, 
    subpats=0x7ffff02010e8, global=0, use_flags=0, flags=0, start_offset=0)
  at /home/vagrant/php-src/ext/pcre/php_pcre.c:585
0x0000000000585a5c in php_do_pcre_match (execute_data=0x7ffff0214260, 
    return_value=0x7ffff0214100, global=0) 
  at /home/vagrant/php-src/ext/pcre/php_pcre.c:574
```

The above message indicates we've returned back to php_do_pcre_match, let's investigate the local variables available to us.

```
(gdb) info locals
regex = 0x7ffff0264dc0
subject = 0x7ffff02028a0
pce = 0x1a98b70
subpats = 0x7ffff02010e8
flags = 0
start_offset = 0
__PRETTY_FUNCTION__ = "php_do_pcre_match"
```

We know that the 3rd argument of preg_match takes a variable to return an array of the matches as subpatterns. The results are held in the subpats* pointer, let's find out more about it.

First, let's find out the type of subpats using the ptype command.

```c
(gdb) ptype subpats
type = struct _zval_struct {
    zend_value value;
    union {
        struct {...} v;
        uint32_t type_info;
    } u1;
    union {
        uint32_t var_flags;
        uint32_t next;
        uint32_t cache_slot;
        uint32_t lineno;
        uint32_t num_args;
        uint32_t fe_pos;
        uint32_t fe_iter_idx;
    } u2;
} *
```

The above output indicates that subpats is a pointer to a _zval_struct that holds a zend_value type named value. What's a zend_value? It's the generic data type PHP uses internally for most of its primitives.

We can find out more information about zend_value using the same ptype command. Note, that we can query the type directly or a variable of that type. I.e. ptype zend_value would return the same information.

```c
(gdb) ptype subpats->value
type = union _zend_value {
    zend_long lval;
    double dval;
    zend_refcounted *counted;
    zend_string *str;
    zend_array *arr;
    zend_object *obj;
    zend_resource *res;
    zend_reference *ref;
    zend_ast_ref *ast;
    zval *zv;
    void *ptr;
    zend_class_entry *ce;
    zend_function *func;
    struct {
        uint32_t w1;
        uint32_t w2;
    } ww;
}
```

The above exposes the generic data structure PHP uses internally for holding values. We know the return type is an array, so we expect zend_array *arr to hold our information.

Next, we print the type of a zend_array.

```c
(gdb) ptype subpats->value->arr
type = struct _zend_array {
    zend_refcounted gc;
    union {
        struct {...} v;
        uint32_t flags;
    } u;
    uint32_t nTableSize;
    uint32_t nTableMask;
    uint32_t nNumUsed;
    uint32_t nNumOfElements;
    uint32_t nInternalPointer;
    zend_long nNextFreeElement;
    Bucket *arData;
    uint32_t *arHash;
    dtor_func_t pDestructor;
} *
```

Aha! PHP uses a 'bucket' concept to store it's array data. We expected 1 match from our unit test on the word 'Hello', let's find out how many items are in the subpats array.

```
(gdb) print subpats->value->arr->nNumOfElements
$1 = 1
```
So there is one element in our array, presumably held in the arData pointer to a Bucket. Let's find out more about the structure of a Bucket type by querying the type directly instead of the arData pointer.

```c
(gdb) ptype Bucket
type = struct _Bucket {
    zval val;
    zend_ulong h;
    zend_string *key;
}
```

So a Bucket consists of a val and a key. A zval has a value that's a zend_value, and we know the array result should contain a string for the subpattern match. Therefore subpats->value->arr->arData->val->value->str should be a zend_string with a length property and a char val.

```
(gdb) print subpats->value->arr->arData->val->value->str->len
$2 = 7
```

So our result has a length of 7. Let's look at the result itself. GDB print command (or p or x) has a number of additional and useful features. First, we can specify the output format, and for arrays we can pass our length using the @ operator.

```
(gdb) print/c subpats->value->arr->arData->val->value->str->val@7
$3 = {{72 'H'}, {101 'e'}, {108 'l'}, {108 'l'}, {111 'o'}, {44 ','}, {32 ' '}}
```

And there it is, our match "Hello, " being returned to PHP.

### Summary

What have we learnt? Zval's are just a struct that contain's a zend_value, and a zend_value is a generic data type that can represent any PHP value. A PHP array consists of a "bucket" structure (among other things), which is ultimately just a reference to another zval (i.e. any type). 

We have a zval -> zend_value -> array -> bucket -> zval -> zend_value -> str where our subpattern match is held.

As a final note, it's important to know that all PHP functions are exposed to GDB through a symbol table that prefixes them with zif_. For example, we could have chosen to break on zif_preg_match insterad of php_do_pcre_match initially. This would have broken at the static function wrapper around php_do_pcre_match. Global object functions are exposed under the zim_ prefix with the pattern zim_classname_methodname.

Happy debugging!

