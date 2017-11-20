---
title: MINSTRUCTOR(1)
author: Christoph Klein
date: 2017-11-20
header: User Guide
...

# NAME

minstructor - measurement instructor

# SYNOPSIS

**minstructor** [**-n** *repititions*] [**-o** *path*[*prefix*]] [**-b** *backend*] [**-f**] [**-a** "*bargs*"] [**-v**] [**-h**] [**-d**] [**--dry-run**] "*cmd0*" "*cmd1*" ...

# DESCRIPTION

You give command patterns *cmd* to the measurement instructor each describing
the execution of a program over multiple command line arguments. A *cmd* might
contain expressions that will be parsed and interpreted as a set of command
line values:

set expression       | also known as
---------------------|--------------------------------------------
[4,a,8,...]          | simple list
range(0,20,3)        | python-like range (start, end, step)
linspace(0,2,5)      | numpy-like linear range (start, stop, num)
logspace(2,11,10,2)  | numpy-like log range (start, stop, num, base)

The measurement instructor executes the given *cmd* on the cartesian
product of all set expressions (see **EXAMPLE** below).

If you specify a name *prefix* for the output files on the command line, the
standard output of your application executions will be saved appropriately.

Probably you want to collect certain metrics of your application executions
and evaluate them. You can use the **mcollector**(1) to achieve that efficiently.


# OPTIONS

-n *repetitions*
:   Number every unique command is repeated.  If you want to have multiple
    measurement points for the same constellation of parameters, e.g. to
    calculate reasonable mean values, you can use this parameter (*DEFAULT*=1).

-o, \--output-dir *path*[*prefix*]
:   Directory where all output files, which contain the stdout of
    your binary, will be saved.
    Generally you want to save the output files in an empty directory, as
    there can be a lot of them.  If you also give a *prefix* the
    output file names are going to have that *prefix*. E.g.
    */var/data*, */var/data/*, */var/data/foo*,
    where the last example will generate output files with a *foo*
    prefix, if *foo* is not the name of a directory. *minstructor*
    chooses the indices of output files consecutive without overwriting
    any existing files (see **EXAMPLE**).

\--verbose-fnames
:   Add the values of the current parameters to the output file name.
    It is good practice not to use this flag, as decoding information
    in file names is error-prone. You should better include all
    necessary information in the stdout of your application.

-f
:   Do not prompt.

-b, \--backend [slurm|shell]
:   Where to execute your binary (*DEFAULT*=shell). In case of the slurm backend,
    jobs will be sent via sbatch.  Hint: if you want to leave an ssh session
    after starting the *minstructor* , you can execute the script within a
    byobu(1) environment and take the `shell` backend.

-a, \--backend-args "*bargs*"
:   Specify additional *backend arguments*. This option depends on your
    choosen backend. E.g. -a "--exclusive -w compute-node.cluster.com" will
    instruct slurm to execute the submitted jobs on host compute-node.cluster.com.

-h, \--help
:   Show this help message

-v, \--[no-]verbose
:   Run verbosely

-d, \--[no-]debug
:   Debug mode; includes verbosity

\--dry-run
:   Do everything normal, but without executing any of the generated commands

# DEFAULTS

Execute each unique command once with the shell back-end
and without producing any output files.

# EXAMPLE

## I

```
$ minstructor "./binary -k0 foo -k1=range(3) -k2 [a,b]"

./binary -k0 foo -k1=0 -k2 a
./binary -k0 foo -k1=0 -k2 b
./binary -k0 foo -k1=1 -k2 a
./binary -k0 foo -k1=1 -k2 b
./binary -k0 foo -k1=2 -k2 a
./binary -k0 foo -k1=2 -k2 b
```

## II

```
$ minstructor -a "-w host0,host1" -b slurm "./binary -k0 foo -k1 [a,1,c]"

sbatch --wrap "./binary -k0 foo -k1 a" -w host0,host1
sbatch --wrap "./binary -k0 foo -k1 1" -w host0,host1
sbatch --wrap "./binary -k0 foo -k1 c" -w host0,host1
```

## III

```
$ minstructor -o /dir0/dir1/ "./binary -k0 foo -k1=linspace(0,1,3)"

./binary -k foo -k1=0   > /dir0/dir1/out_0.txt
./binary -k foo -k1=0.5 > /dir0/dir1/out_1.txt
./binary -k foo -k1=1.0 > /dir0/dir1/out_2.txt
```

## IV

```
$ ls

out_16.txt out_678.txt other.txt binary

$ minstructor --verbose-fname -o . "./binary -key=range(2)"

  ./binary -key=0 > out_679_0.txt
  ./binary -key=1 > out_678_1.txt
```

# SEE ALSO
**mcollector**(1), **byobu**(1)

https://github.com/codecircuit/minstructor
