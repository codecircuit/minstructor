# Measurement Instructor

If you are tired of writing scripts manually, which instruct
an application you want to benchmark, this program is what
you are searching for. You give lists of command line parameter
values to the Measurement Instructor and it executes your
application with every possible combination of the given parameter set.

If you specify a name prefix for the output files on the command line, the
standard output of your application executions will be saved appropriately.
Generally you want to save the output files in an *empty* directory, as
there can be a lot of them.

E.g. `minstructor -o ./results "./binary --scheme foo --seed=range(3) --param [a,b]"`
will result in executing the following commands:

```
./binary --scheme foo --seed=0 --param a > ./results/out_0.txt
./binary --scheme foo --seed=0 --param b > ./results/out_1.txt
./binary --scheme foo --seed=1 --param a > ./results/out_2.txt
./binary --scheme foo --seed=1 --param b > ./results/out_3.txt
./binary --scheme foo --seed=2 --param a > ./results/out_4.txt
./binary --scheme foo --seed=2 --param b > ./results/out_5.txt
```

You can specify ranges with various patterns:

**Example**               | **Type**
--------------------------|-------------------------
`[4,a,8,...]`             | simple lists
`range(0,20,3)`           | python-like ranges (start, end, step)
`linspace(0,2,5)`         | python numpy-like linear ranges (start, stop, num)
`logspace(3,12,10,2)`     | python numpy-like log ranges (start, stop, num, base)

## Collect execution results

Probably you want to collect certain metrics of your application executions
and evaluate them. You can use the `mcollector` to achieve that efficiently.
The `mcollector` expects multiple files each containing the `stdout` of one
application run. Your application should output *every* relevant information.
E.g. if you execute `./binary --scheme foo --seed=16547`, a `stdout` processable
by the `mcollector` could look like:

```
...
  - scheme -> foo
  - bandwidth =   20 GB/s
    foo bar baz ... weather: "sunny and warm"
    footime: 0.4687 s

    Here you can also write about the bandwidth or scheme etc.
    unless you don't assign it twice.

  - random-seed --> 16547
...
```

You can collect your results, which are saved in output files, in a CSV table
with:

```
mcollector ./results/out_*
``` 

The `mcollector` is able to recognize certain assignment patterns, like they are
shown above, and will extract the words or numerical values *after* the
keywords. It is important that the keywords are *only assigned once* in each
output file. E.g. if the shell expansion in the example above results
in several output files, an example CSV output of the `mcollector` could
look like:

```
scheme,bandwidth,weather,footime,random-seed,data-file-path
foo,20,"sunny and warm",0.4687,16547,/abs/path/results/out_0.txt
foo,10,"rainy",N/A,1756,/abs/path/results/out_1.txt
foo,0,"windy and rainy",0.4864,1654,/abs/path/results/out_2.txt
```

If a file does not contain a keyword assignment, which is found in
other files, the value is substituted with N/A.

## Requirements

To build the manual pages you need to have `pandoc`, which can be installed
with most system package manager programs.
I wrote the scripts in Ruby, thus you need a Ruby implementation
and the Ruby package manager `gem` to install the required RubyGems:

```shell
$ gem install progressbar
$ gem install test-unit # to run the tests
$ gem install rake # to run the tests and build the manual pages
```

If your shell does not find the RubyGems, it might be helpful to add
`$(ruby -e 'print Gem.user_dir')/bin` to your `PATH` environment variable.

## Installation

Up to know the installation (`rake install`) will simply copy the scripts to 
`/usr/local/bin`. The manual pages are installed to `$(man -w | cut -d: -f1)/man1`.

## Documentation

You will find more information on the manual pages, which can be built
with `rake man`, or built and installed with `rake install`.

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
