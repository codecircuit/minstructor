---
title: minstructor(1) User Guide
author: Christoph Klein
date: 2017-04-16
...

# NAME

minstructor - measurement instructor

# SYNOPSIS

**minstructor** [**-o** *path*[*prefix*]] "*cmd0*" "*cmd1*" ...

# DESCRIPTION

If you are tired of writing scripts manually, which instruct
an application you want to benchmark, this program is what
you are searching for. You gave lists of commmand line parameter
values to the Measurement Instructor and he executes your
application with every possible combination of the given parameters.

If you specify a name prefix for the output files on the command line, the
standard output of your application executions will be saved appropriately.

Probably you want to collect certain metrics of your application executions
and evaluate them. You can use the `mcollector(1)` to achieve that efficiently.


# SEE ALSO
mcollector(1), byobu(1)

# EXAMPLE
minstructor -c "./binary -k0 foo -k1=range(3) -k2 [a,b]" will be expanded to

```
  ./binary -k0 foo -k1=0 -k2 a
  ./binary -k0 foo -k1=0 -k2 b
  ./binary -k0 foo -k1=1 -k2 a
  ./binary -k0 foo -k1=1 -k2 b
  ./binary -k0 foo -k1=2 -k2 a
  ./binary -k0 foo -k1=2 -k2 b
```

# OPTIONS

-c, \--cmd "*PATH/TO/BINARY* [*FLAG* [*VAL*|*RANGE*]]"
:   *TODO: REMOVE -c FLAG* You can specify ranges on various ways, e.g.:
    **TODO: find out how to show quotations marks here**
    [4,a,8,...]           simple lists
    range(0,20,3)         python-like ranges (start,end,step)
    linspace(0,2,5)       numpy-like linear ranges (start,stop,num)
    logspace(1,1000,5,10) numpy-like log ranges (start,stop,num,base)

## Sub option

-n *repetitions*
:   Number every unique command is repeated.  If you want to have multiple
    measurement points for the same constellation of parameters, e.g. to
    calculate reasonable mean values, you can use this parameter (*DEFAULT*=1).

-o, --output-dir *path*[*prefix*]
:   Directory where all output files, which contain the stdout of
    your binary, will be saved.
    Generally you want to save the output files in an empty directory, as
    there can be a lot of them.  If you also give a *prefix* the
    output file names are going to have that *prefix*. E.g.
    */var/data*, */var/data/*, */var/data/foo*,
    where the last example will generate output files with a *foo*
    prefix, if *foo* is not the name of a directory.

-f
:   Do not prompt. Be careful with this flag, as this can result
    in files being overwritten.

-b, \--backend [slurm|shell]
:   DEFAULT=shell; Where to execute your binary. In case of the slurm backend,
    jobs will be sent via sbatch.  Hint: if you want to leave an ssh session
    after starting the *minstructor* , you can execute the script within a
    byobu(1) environment and take the `shell` backend.

-a, \--backend-args "ARGS"
:   Specify specific additional backend arguments. This option depends on your
    choosen backend. E.g. -a "--exclusive -w compute-node.cluster.com" will
    instruct slurm to execute the submitted jobs on host compute-node.

-h, \--help
:   Show this help message

-v, \--[no-]verbose
:   Run verbosely

-d, \--[no-]debug
:   Debug mode; includes verbosity

\--dry-run
:   Do everything normal, but without executing any of the generated commands

# DEFAULTS
todo
