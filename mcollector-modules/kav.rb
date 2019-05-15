require_relative './base.rb'

#########
# REGEX #
#########
# the following variables should be global to test them when
# including this file from another ruby script

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

# This function returns a regex which matches any KEYWORD SPACE LINK
# SPACE VALUE constellations. Moreover the VALUE and KEYWORD are
# captured, and can be obtained by matchdata["value"], or matchdata["keyword"].
# If the keyword is omitted, it is assumed that the keyword can consist of
# [_-[:alnum:]], which are numbers, alphabetic characters, underscore and
# minus.
def getKeyValueReg(keyword=nil)
	if keyword != nil
		# If the keyword is given everything in the keyword should be matched
		# literally, thus we escape every special regex character
		safe_keyword = Regexp.quote(keyword)
		# We must us [[:blank:]] instead of \s, because \s includes \n!
		/(?<keyword>#{safe_keyword})[[:blank:]]*#{$linkReg}[[:blank:]]*#{$valReg}/
	else
		if $options.wkeywords           # '+?' = non greedy '+'
			/(?<keyword>[^,]+?)[[:blank:]]*#{$linkReg}[[:blank:]]*#{$valReg}/
		else                       # '+?' = non greedy '+'
			/(?<keyword>[_\-[:alnum:]]+?)[[:blank:]]*#{$linkReg}[[:blank:]]*#{$valReg}/
		end
	end
end

# take a keyword and a string and search for the first
# part, which matches the Regexp. From that match we
# want to have the first capture, which is not nil
def grepValue(key, str)
	return md["value"] if md != nil
	return nil
end

module MCollectorModule

	##
	# Key Assignment Value Module
	#
	# Searches for KEY ASSIGNMENTSYMBOL VALUE patterns
	# the KEYs must be given as optional args

	class KAV < Base
		def apply(input_str, args)

			args = {
				:keywords => [],
				:prune => true,
			}.merge(args)

			row = {}

			pruned_str = input_str.clone

			args[:keywords].each do |key|
				md = pruned_str.match(getKeyValueReg(key))
				if !md.nil?
					val = md["value"]
					pruned_str = md.pre_match + md.post_match # remove match from str
					row[key] = val
				end
			end
			return [[row], opt_args[:prune] ? pruned_str : input_str]
		end

		def name()
			return "kav"
		end

		def help()
			return ' :keywords => ["takeme", "grepmyval"], 
			         :prune => true # remove matches from string for next module'
		end
	end

end
