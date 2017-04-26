---
title: mcollector(1) User Guide
author: Christoph Klein
date: 2017-04-16
...

# NAME

mcollector - measurement collector

# SYNOPSIS

**mcollector** [**-k** *keyword*[,...]] [**-i** *keyword*[,...]] [**-o** *csvfile*] [**-f**] *file0* *file1* ...

# DESCRIPTION

You give simple text *files* to the mcollector and he searches for
typical assignment patterns within that *files* to generate a CSV table.
This is reasonable if each files content assigns each keyword at
most once.

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

-k *keyword0*,*keyword1*, ...
:   Comma seperated list of *keywords* the mcollector should search for.
    This disables the automatic detection of keywords.

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
