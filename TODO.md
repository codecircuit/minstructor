# modularization of mcollector

Each module should have:

- help message regarding module specific parameters
- takes an input string
- removes the processed characters from the input string
  if set by a flag variable
- tests

## standard modules

- keyword detector: uses **given** keywords and extracts the values
- automatic keyword detector: searches for key-assignment-symbol-value patterns
  - takes ignored keywords as parameters
  - allow weird keywords


## on the CLI

- user can set the order and used modules. E.g. `--module-enable-keywords '{:keywords => ["foo","bar","baz"]}' --module-enable-csv '{:separator => ","}'`
  `--module-enable-foomodule ./hash-for-foomodule-in-file.txt`,
  which would execute module `keywords` and subsequently module `csv` with additional module arguments. The module specific arguments
  are given as Ruby hash. In general: `--module-enable-MODULENAME`.
- the automatic keyword detection module is enabled as default
- if one module is specified automatic keyword detection is not activated automatically
- help message for a module `--module-help-keywords`, or `--module-help-csv`
