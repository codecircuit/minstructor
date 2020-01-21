---
title: MINSTRUCTOR(1)
author: Christoph Klein
date: 2018-08-20
header: User Guide
...

# NAME

minstructor - measurement instructor

# SYNOPSIS

**minstructor** [**-n** *repititions*] [**-o** *path*] [**-b** *backend*] [**-f**] [**-a** "*bargs*"] [**-v**] [**-h**] [**-d**] [**--dry-run**] "*cmd0*" "*cmd1*" ...

# DESCRIPTION

You give command patterns *cmd* to the measurement instructor each describing
the execution of a program over multiple command line arguments. A *cmd* might
contain expressions that will be parsed and interpreted as a set of command
line values:

set expression       | also known as
---------------------|--------------------------------------------
[4,a,8,...]          | simple list
range(0,20,3)        | python-like range (start, end, step=1)
linspace(0,2,5)      | numpy-like linear range (start, stop, num)
logspace(2,11,10,2)  | numpy-like log range (start, stop, num, base=10)
logrange(4,12,3,5)   | similar to logspace but for integers (start, end, step=1, base=2)
fromfile(./file.txt) | reads linewise from a file

The measurement instructor executes the given *cmd* on the cartesian
product of all set expressions (see **EXAMPLE** below).

If you specify an output *path* for the output files on the command line, the
standard output of your application executions will be saved appropriately.
To enable multiple simultaneously **minstructor** executions, a new directory for the
output files must be created, to avoid runtime hazards.

Probably you want to collect certain metrics of your application executions
and evaluate them. You can use the **mcollector**(1) to achieve that efficiently.


# OPTIONS

-n *repetitions*
:   Number every unique command is repeated.  If you want to have multiple
    measurement points for the same constellation of parameters, e.g. to
    calculate reasonable mean values, you can use this parameter (*DEFAULT*=1).

-t *seconds*
:   Seconds between two job submissions. This flag only has an effect if
    a job scheduling system (e.g. Slurm) is chosen as back end.

-o, \--output-dir *path*
:   Directory where all output files, which contain the stdout of
    your binary, will be saved. If the trailing directory does not
    exist, it will be created. Within the given directory
    `minstructor` will create one directory for each execution of
    `minstructor` (see **EXAMPLE**).

\--verbose-fnames
:   Add the values of the current parameters to the output file name.
    It is good practice not to use this flag, as decoding information
    in file names is error-prone. You should better include all
    necessary information in the stdout of your application.

-f
:   Do not prompt.

\--no-progress-bar
:   Hide the progress bar

-b, \--backend [slurm|shell]
:   Where to execute your binary (*DEFAULT*=shell). In case of the slurm backend,
    jobs will be sent via sbatch. Hint: if you want to leave an `ssh` session
    after you started the *minstructor* , you can execute the script within a
    **byobu(1)** environment.

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
$ minstructor --verbose-fname -o /dir0/dir1/ "./binary -k0 foo -k1=linspace(0,1,3)"

./binary -k foo -k1=0   > /dir0/dir1/minstructor_0/out_0_0.txt
./binary -k foo -k1=0.5 > /dir0/dir1/minstructor_0/out_1_0.5.txt
./binary -k foo -k1=1.0 > /dir0/dir1/minstructor_0/out_2_1.0.txt
```

## IV

```
$ minstructor -o . 'VAR=[1,2,3]; ./binary -k $VAR -j $VAR'

  ./binary -k 1 -j 1 > ~/minstructor_0/out_0.txt
  ./binary -k 2 -j 2 > ~/minstructor_0/out_1.txt
  ./binary -k 3 -j 3 > ~/minstructor_0/out_2.txt
```

## V

```
$ # backend argument expansion is also possible
$ minstructor -b slurm -a "-w node[0,1]" "./binary -k [1,2]"

  sbatch -w node0 --wrap './binary -k 1'
  sbatch -w node0 --wrap './binary -k 2'
  sbatch -w node1 --wrap './binary -k 1'
  sbatch -w node1 --wrap './binary -k 2'
```

# SEE ALSO
**mcollector**(1), **byobu**(1)

https://github.com/codecircuit/minstructor
