# Write your own module

In principle a module simply takes an input string, extracts
the data, returns the extracted data and the possibly changed
input string:

```
+-------------+    +----------+     +----------+
| output file +--->+ module A +---->+ module B +----> ...
+-------------+    +----------+     +----------+
```

To keep interfaces between modules consistent each module
provides a function `apply(input_str, args)`, which takes the input
string and additional/optional/mandatory arguments in a Ruby Hash
object. Up to now each module should have the `:prune` argument,
which declares if the output string of the module is allowed to be
different from the input string.

The `apply` function of a module returns the collected information
and the string for the next module. The collected information is
returned as a list of Hashes. Each hash will be found later in one
row in the final CSV file.

I recommend to take `./akav.rb` as a starting point
for your own module. After you finished your class you must register
your module in `./available-modules.rb` and add a proper installation
in `Rakefile`.
