---
title: minstructor
author: Christoph Klein
...

# Measurement Instructor

If you are tired of writing scripts manually, which instruct
an application you want to benchmark, this program is what
you are searching for. You gave lists of commmand line parameter
values to the Measurement Instructor and he executes your
application with every possible combination of the given parameters.

if you specify a name prefix for the output files on the command line, the
standard output of your application executions will be saved appropriately.
Generally you want to save the output files in an *empty* directory, as
there can be a lot of them.

## Collect execution results
Probably you want to collect certain metrics of your application executions
and evaluate them. You can use the `mcollector(1)` to achieve that efficiently.

## Command line parameters

### `-c, --cmd "/path/to/binary [<key> {<val>|<range>}]"`
You can specify ranges on various ways, e.g.:

```
  [4,a,8,...]           simple lists
  range(0,20,3)         python-like ranges
  linspace(0,2,5)       numpy-like linear ranges
  logspace(1,1000,5,10) numpy-like log ranges
```

E.g. -c "./binary -k0 foo -k1=range(3) -k2 [a,b]" will be expanded to
```
  ./binary -k0 foo -k1=0 -k2 a
  ./binary -k0 foo -k1=0 -k2 b
  ./binary -k0 foo -k1=1 -k2 a
  ./binary -k0 foo -k1=1 -k2 b
  ./binary -k0 foo -k1=2 -k2 a
  ./binary -k0 foo -k1=2 -k2 b
```

### `-n <repetitions>`
Number every unique command is repeated.  If you want to have multiple
measurement points for the same constellation of parameters, e.g. to
calculate reasonable mean values, you can use this parameter (DEFAULT=1)

### `-o, --output-dir <path/to/output/personal_prefix_>`
Directory where all output files, which contain the stdout of
your binary, will be saved.

### `-f`
Do not prompt. Be careful with this flag, as this can result
in files being overwritten.

### `-b, --backend [slurm|shell]`
DEFAULT=shell; Where to execute your binary.  In case of the slurm backend, jobs
will be sent via sbatch.  Hint: if you want to leave an ssh session after
starting the *minstructor* , you can execute the script within a `byobu`
environment and take the `shell` backend.

### `-a, --backend-args "<args>"`
Specify specific additional backend arguments. This option depends on your
choosen backend.
E.g. `-a "--exclusive -w compute-node.cluster.com"` will instruct slurm to
execute the submitted jobs on host `compute-node`.

### `-h, --help`
Show this help message

### `-v, --[no-]verbose`
Run verbosely

### `-d, --[no-]debug`
Debug mode; includes verbosity

### `--dry-run`
Do everything normal, but without executing any of the generated commands

## minstructor VS google-benchmark-lib
TODO
