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

E.g. `minstructor -c "./binary -k0 foo -k1=range(3) -k2 [a,b]" -o output/file_`
will result in executing the following commands:

```shell
  ./binary -k0 foo -k1=0 -k2 a > output/file_0.txt
  ./binary -k0 foo -k1=0 -k2 b > output/file_1.txt
  ./binary -k0 foo -k1=1 -k2 a > output/file_2.txt
  ./binary -k0 foo -k1=1 -k2 b > output/file_3.txt
  ./binary -k0 foo -k1=2 -k2 a > output/file_4.txt
  ./binary -k0 foo -k1=2 -k2 b > output/file_5.txt
```

You can specify ranges with various patterns:

**Example**               | **Type**
--------------------------|-------------------------
`[4,a,8,...]`             | simple lists
`range(0,20,3)`           | python-like ranges
`linspace(0,2,5)`         | python numpy-like linear ranges
`logspace(1,1000,5,10)`   | python numpy-like log ranges

## Collect execution results
Probably you want to collect certain metrics of your application executions
and evaluate them. You can use the `mcollector` to achieve that efficiently.
The `mcollector` expects multiple files, which contain the `stdout` of one
application run. Your application should output every relevant information,
e.g. if you execute `./binary -k0 foo -k1=2 -k2 b` a suitable output for
the `mcollector` could look like this:

```shell
...
  - keyword0 -> foo
  - keyword1 =   2
  - keyword2 b
  - footime: 0.4687 s
  - bar-val = 16547
...
```

Now you can collect your results into a CSV table on stdout with  
`mcollector -d path/to/output/files -k keyword0,keyword1,keyword2,footime,bar-val,no-keyword`. 
The `mcollector` is able to recognize certain assignment patterns, as they are
shown above and will extract the words or numeric values after the keywords. It
is important that the keywords are *only mentioned once* in each output file. If
there are several .txt-files containing the `stdout` of your application in
`path/to/output/files`, the `mcollector` could generate something like:

```
keyword0,keyword1,keyword2,footime,bar-val,no-keyword
foo,2,a,0.4687,16547,N/A
foo,1,b,0.4779,1756,N/A
foo,0,a,0.4864,1654,N/A
```

## minstructor VS google-benchmark-lib
Why I prefer `minstructor` in comparison to the Google Benchmark library
https://github.com/google/benchmark

**google-benchmark**              | **minstructor**
----------------------------------|---------------------------------------------
-less predefined range functions  | +predefined numpy like range functions
-long running jobs (error-prone)  | +independent jobs
                                 | -many (temporary) output files
-functions should have already    | +benchmarking and testing
been tested                       |
+ good for real micro benchmarks  | - not fast for benchmarks with
\                                 |   timings similar to the prog.
\                                 |   launch overhead
- library dependency              | - prog must also be installed
- syntax understanding needs time | + mainly self explanatory
- no slurm support                | + multiple backends (also slurm)
- functions must not have `cout`  | + functions *should* have various
\                                 |   informative output
- ouput to CSV: every benchmark   |
  must contain every self defined |
  counter                         |
- time measurement points must be |
  set manually anyways as in most |
  cases we do not want to measure |
  the time of a whole function    |
- strong coupling between your    |
  application and the API of the  |
  library                         |

