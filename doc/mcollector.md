---
title: MCOLLECTOR(1)
author: Christoph Klein
date: 2019-05-15
header: User Guide
...

# NAME

mcollector - measurement collector


# SYNOPSIS

**mcollector** [--module-enable-MODULENAME [MODULEARGS]] [**-o** *csvfile*] [**-f**] [**-s**|**--sort**] [**-h**|**--help**] [**-v**|**--verbose**] *file0* *file1* ... *dir0* *dir1* ...


# DESCRIPTION

You give simple text *files* to the `mcollector` and he searches for
typical assignment patterns within that *files* to generate a CSV table.
This is reasonable if the content of each file assigns each keyword at
most once. If a directory is given `mcollector` processes all files
in that directory.

Without a specified module the measurement collector tries to search by itself for
typical key value assignment patterns in the given text files (see **EXAMPLE**
below).
In general a key value assignment expression is composed of *KEY* *LINK*
*VALUE*.  The link symbol (:,=>,->,=) must exist and is not allowed to be a space character.
Between the three expressions there can be a variable amount of tab and space
characters. If a file does not contain a keyword assignment, the value is substituted
with "N/A". Look into the source code to see the regular expressions I used
for parsing key value assignments.

`mcollector` is a powerful modularized information aggregator. You can specify
multiple modules to extract information from the given text file. 
That means you can chain
modules to extract different patterns out of your text file. If no module is
enabled on the command line, the default module is AKAV (automated key assignment value).
Which behaves as described above. If at least one module is specified manually,
no hidden modules are activated. The order in which the modules are enabled is
also the order of execution. This is important if a module changes the input
string, which was read from the input file and passes it to the next module.
This makes sense, because some modules can extract and remove their information to make the
string processable by the next module.

To get proper output *files* from your application you can use
the **minstructor**(1) to achieve that efficiently.

# OPTIONS

--module-enable-MODULENAME [MODULEARGS]
:   Too see all available modules use `--help`. 
    Each module takes mandatory/optional arguments, which
    are given as a Ruby Hash object.

--module-help-MODULENAME 
:   Get more information about a module

-w, \--weird-keywords
:   Allow keywords to contain all characters except comma. This has only
    an effect for automatic keyword detection. Usually this is only useful if
    you have one keyword assignment per line.

-o, \--output *csvfile*
:   Path to output the CSV data. If not specified the mcollector will
    print the CSV data to stdout. This flag might result in asking
    for confirmation in case of overwriting a file.

--sql-database *string*
:   Name of the SQL database. If one sql options is given, the others must also be
    declared. The collected data is then written to a table in this database.

--sql-table *string*
:   Name of the SQL table

--sql-user *string*
:   SQL username

--sql-password *string*
:   SQL user password

--sql-host *URL*
:   URL of the host, which has the SQL server running

--separator *string*
:   If a different separator than ',' is desired it can be chosen here.

-r, \--recursive
:   Search recursively for data files in given directories.

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
$ mcollector --enable-module-akav '{ :nokeywords => ["ERROR"] }' ./out_*.txt
  time,scheme-A,throughput,key2,data-file-path
  16546,fast_scheme,164.468e+77,16578,/data/out_0.txt
  16574,fast_scheme,16.48e+65,16873,/data/out_1.txt
$ mcollector --separator '\t,\t' ./out_*.txt
  ...
```

# SEE ALSO
**minstructor**(1), **byobu**(1)

https://github.com/codecircuit/minstructor
