#########
# REGEX #
#########
# Collection of useful regular expressions

$expReg = /[eE][-+]?[[:digit:]]+/ # e.g. e+64 or E-0674
$numReg = /[-+]?[[:digit:]]+(?:\.[[:digit:]]+)?#{$expReg}?/

# The unit regex should allow a lot of symbols, e.g. GB/s, foo^4
# It matches everything except space.
$unitMaxSize        = 10 # maximum size of a unit, e.g. `Byte` has 4
$unitReg          = /\S{1,#{$unitMaxSize}}/

# regex of assignment symbols; the order is crucial; do not change it
$linkReg = /-+>|=+>|=|:/ # divided by logical OR

# numerical value
$quantityReg = /(?<value>#{$numReg})#{$unitReg}?/

# quoted value
$quotationReg = /(?<value>"[^"]+")/

# simple word value
# which must consists of word characters: [a-zA-Z0-9_-]
# the minus is contained, as we want to support detection of
# words like `mp-data.ziti.uni-heidelberg.de`
$wordReg = /(?<value>[\w-]+)/

# date value
# We need a date regex to add it before the quantity regex.
# It is not possible to capture dates with the word regex, as
# the word regex would also capture expressions like e.g.
# `1654MB`, which should generally be captured by the quantity
# regex to extract the number from the pattern.
$dateReg = /(?<value>[0-9]{4}-[0-9]{2}-[0-9]{2})/

# general value regex
# the regular expressions here are processed from left to
# right with decreasing priority.
$valReg = /#{$quotationReg}|#{$dateReg}|#{$quantityReg}|#{$wordReg}/

$nonSpaceValueReg = /(?<value>[^\s]+)/
$csvVal = /(#{$wordReg}|#{$nonSpaceValueReg}|#{$quotationReg}|#{$numReg})/
$csvRow = /(#{$csvVal},)+#{$csvVal},?\n/
$csvReg = /#{$csvRow}{2,}/
