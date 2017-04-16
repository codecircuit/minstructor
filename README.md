# Measurement Instructor

**DISCLAIMER**: The software is currently in an alpha stage, thus not
all mentioned features are available yet. The Beta-Release is planned
for the end of April. For the current status take a look into the Wiki.

If you are tired of writing scripts manually, which instruct
an application you want to benchmark, this program is what
you are searching for. You give lists of commmand line parameter
values to the Measurement Instructor and he executes your
application with every possible combination of the given parameters.

If you specify a name prefix for the output files on the command line, the
standard output of your application executions will be saved appropriately.
Generally you want to save the output files in an *empty* directory, as
there can be a lot of them.

E.g. `minstructor -c "./binary -k0 foo -k1=range(3) -k2 [a,b]" -o ./results`
will result in executing the following commands:

```shell
  ./binary -k0 foo -k1=0 -k2 a > ./results/out_0.txt
  ./binary -k0 foo -k1=0 -k2 b > ./results/out_1.txt
  ./binary -k0 foo -k1=1 -k2 a > ./results/out_2.txt
  ./binary -k0 foo -k1=1 -k2 b > ./results/out_3.txt
  ./binary -k0 foo -k1=2 -k2 a > ./results/out_4.txt
  ./binary -k0 foo -k1=2 -k2 b > ./results/out_5.txt
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
The `mcollector` expects multiple files each containing the `stdout` of one
application run. Your application should output *every* relevant information.
E.g. if you execute `./binary -k0 foo -k1=2 -k2 b`, a `stdout` processable 
by the `mcollector` could look like:

```shell
...
  - key0 -> foo
  - key1 =   2
  other words key2: "long string a"
footime: 0.4687 s
     you can also mention key2 here
  - bar-val --> 16547
...
```

You can collect your results, which are saved in output files, in a CSV table
with:

```
mcollector -k key0,key1,key2,footime,bar-val,no-key ./results/out_*
``` 

The `mcollector` is able to recognize certain assignment patterns, like they are
shown above, and will extract the words or numerical values *after* the
keywords. It is important that the keywords are *only assigned once* in each
output file. E.g. if the shell expansion in the example above results
in several output files, an example CSV output of the `mcollector` could
look like:

```
keyword0,keyword1,keyword2,footime,bar-val,no-keyword,data-file-path
foo,2,"long string a",0.4687,16547,N/A,/abs/path/results/out_0.txt
foo,1,"long string b",0.4779,1756,N/A,/abs/path/results/out_1.txt
foo,0,"long string c",0.4864,1654,N/A,/abs/path/results/out_2.txt
```

## minstructor VS google-benchmark-lib
Why I prefer `minstructor` in comparison to the Google Benchmark library
https://github.com/google/benchmark

**google-benchmark**              | **minstructor**
----------------------------------|---------------------------------------------
-less predefined range functions  | +predefined numpy like range functions
-long running jobs (error-prone)  | +independent jobs
\                                 | -many (temporary) output files
-functions should have already been tested  | +benchmarking and testing
+good for real micro benchmarks   | -not fast for benchmarks with timings similar to the prog. launch overhead
-library dependency               | -`minstructor` must also be installed
-syntax understanding needs time  | +mainly self explanatory
-no slurm support                 | +multiple backends (also slurm)
-functions must not have `cout`   | +functions *should* have various informative output
-ouput to CSV: every benchmark must contain every self defined counter | 
-time measurement points must be set manually anyways as in most cases we do not want to measure  the time of a whole function | 
-strong coupling between your application and the API of the library | 
