---
title: MCOLLECTOR(1)
author: Christoph Klein
date: 2017-11-20
header: User Guide
...

# NAME

mcollector - measurement collector


# SYNOPSIS

**mcollector** [**-k** *keyword*[,...]] [**-i** *keyword*[,...]] [**-o** *csvfile*] [**-f**] [**-s**|**--sort**] [**-h**|**--help**] [**-v**|**--verbose**] *file0* *file1* ...


# DESCRIPTION

You give simple text *files* to the mcollector and he searches for
typical assignment patterns within that *files* to generate a CSV table.
This is reasonable if the content of each file assigns each keyword at
most once.

Without the **-k** flag the measurement collector tries to search by itself for
typical key value assignment patterns in the given text files (see **EXAMPLE**
below).  In general a key value assignment expression is composed of *KEY* *LINK*
*VALUE*.  The link symbol (:,=>,->,=) must exist and is not allowed to be a space character.
Between the three expressions there can be a variable amount of tab and space
characters. If a file does not contain a keyword assignment, the value is substituted
with "N/A". Look into the source code to see the regular expressions I used
for parsing key value assignments.

To get proper output *files* from your application you can use
the **minstructor**(1) to achieve that efficiently.


# OPTIONS

-k, \--keywords *keyword0*,*keyword1*, ...
:   Comma seperated list of keywords the mcollector should search for.
    This disables the automatic detection of keywords.

-i, \--ignore-keywords *keyword0*,*keyword1*, ...
:   Comma seperated list of keywords the mcollector should ignore.
    This is only reasonable without the **-k** flag. This is useful,
    e.g. to omit text like 'ERROR: foo bar', which will be interpreted
    as an key value assignment.

-w, \--weird-keywords
:   Allow keywords to contain all characters except comma. This has only
    an effect for automatic keyword detection. Usually this is only useful if
    you have one keyword assignment per line.

-o, \--output *csvfile*
:   Path to output the CSV data. If not specified the mcollector will
    print the CSV data to stdout. This flag might result in asking
    for confirmation in case of overwriting a file.

-f
:   Do not prompt. This might result in overwriting files.

-s, \--sort
:   Sort the CSV data.

-h, \--help
:   Show this help message.

-v, \--[no-]verbose
:   Run verbosely.

-d, \--[no-]debug
:   Run in Debug mode (includes verbosity).


# EXAMPLE

Assume there are several output files in the current directory, which
have similar content:

```
$ pwd
  /data
$ ls
  out_0.txt out_1.txt ...
$ cat out_0.txt
  ...
  time =  16546ms  # time for calculation
  scheme-A --> fast_scheme
  throughput ===>   164.468e+77GB/s # I wish I had it
  key2: 16578 Steps
  ...
$ cat out_321.txt
  ERROR: this run has not been successful
$ mcollector -i ERROR ./out_*.txt
  time,scheme-A,throughput,key2,data-file-path
  16546,fast_scheme,164.468e+77,16578,/data/out_0.txt
  16574,fast_scheme,16.48e+65,16873,/data/out_1.txt
  ...
```

# SEE ALSO
**minstructor**(1), **byobu**(1)

https://github.com/codecircuit/minstructor
