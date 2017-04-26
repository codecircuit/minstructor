---
title: mcollector(1) User Guide
author: Christoph Klein
date: 2017-04-16
...

# NAME

mcollector - measurement collector

# SYNOPSIS

**mcollector** [**-k** *keyword*[,...]] [**-i** *keyword*[,...]] [**-o** *csvfile*] [**-f**] [**-s**|**--sort**] [**-h**|**--help**] [**-v**|**--verbose**] *file0* *file1* ...

# DESCRIPTION

You give simple text *files* to the mcollector and he searches for
typical assignment patterns within that *files* to generate a CSV table.
This is reasonable if each files' content assigns each keyword at
most once.

Without the **-k** flag the measurement collector tries to search by itself
for typical key value assignment patterns in the given files. With the
use of ruby regular expressions the mcollector is able to understand
key value assignments like:

TODO: move to examples
```
...
time =  16546ms  # time for calculation
scheme-A --> fast_scheme
throughput ===>   164.468e+77GB/s # I wish I had it
otherKey: 16578 Steps
...
```

In general a key value assignment expression contains of *KEY* *LINK* *VALUE*.
The link symbol must exist and is not allowed to be a space character. Between
the three expressions there can be a variable amount of tab and space
characters. For the regular expressions themselves you should look into
the source code.

To get proper output *files* from your application you can use
the **minstructor**(1) to achieve that efficiently.

# EXAMPLE

## I
**TODO: prevent line break here**  
`$ minstructor "./binary -k0 foo -k1=range(3) -k2 [a,b]"`
```
./binary -k0 foo -k1=0 -k2 a
./binary -k0 foo -k1=0 -k2 b
./binary -k0 foo -k1=1 -k2 a
./binary -k0 foo -k1=1 -k2 b
./binary -k0 foo -k1=2 -k2 a
./binary -k0 foo -k1=2 -k2 b
```

# OPTIONS

-k, \--keywords *keyword0*,*keyword1*, ...
:   Comma seperated list of keywords the mcollector should search for.
    This disables the automatic detection of keywords.

-i, \--ignore-keywords *keyword0*,*keyword1*, ...
:   Comma seperated list of keywords the mcollector should ignore.
    This is only reasonable without the **-k** flag. This is useful,
    e.g. to omit text like 'ERROR: foo bar', which will be interpreted
    as an key value assignment.

-o, --output *csvfile*
:   Path to output the CSV data. If not specified the mcollector will
    print the CSV data to stdout. This flag might result in asking
    for confirmation in case of overwriting a file.

-f
:   Do not prompt. This might result in overwriting files.

-s, \--sort
:   Sort the CSV data.

-h, \--help
:   Show this help message

-v, \--[no-]verbose
:   Run verbosely

-d, \--[no-]debug
:   Debug mode; includes verbosity

# DEFAULTS

Execute each unique command once with the shell backend
and without producing any output files.

# SEE ALSO
**mcollector**(1), **byobu**(1)
