require_relative './base.rb'
require_relative '../regular-expressions.rb'

# This function returns a regex which matches any KEYWORD SPACE LINK
# SPACE VALUE constellations. Moreover the VALUE and KEYWORD are
# captured, and can be obtained by matchdata["value"], or matchdata["keyword"].
# If the keyword is omitted, it is assumed that the keyword can consist of
# [_-[:alnum:]], which are numbers, alphabetic characters, underscore and
# minus.
def getKeyValueReg(args = {})
	args = {
		:keyword => nil,
		:allow_weird_keywords => false
	}.merge(args)

	if args[:keyword] != nil
		# If the keyword is given everything in the keyword should be matched
		# literally, thus we escape every special regex character
		safe_keyword = Regexp.quote(keyword)
		# We must us [[:blank:]] instead of \s, because \s includes \n!
		/(?<keyword>#{safe_keyword})[[:blank:]]*#{$linkReg}[[:blank:]]*#{$valReg}/
	else
		if args[:allow_weird_keywords] # '+?' = non greedy '+'
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

		def default_args
			return DefaultArgs.new({
				:keywords => [[], "Search for these keywords (mandatory)"],
				:prune => [true, "Remove extracted information for next module"],
			})
		end

		def apply(input_str, args)

			args = default_args.merge(args)
			if args[:keywords].empty?
				raise ArgumentError, "Module KAV needs keywords to process!"
			end

			row = {}

			pruned_str = input_str.clone

			args[:keywords].each do |key|
				md = pruned_str.match(getKeyValueReg(:keyword => key))
				if !md.nil?
					val = md["value"]
					pruned_str = md.pre_match + md.post_match # remove match from str
					row[key] = val
				end
			end
			return [[row], args[:prune] ? pruned_str : input_str]
		end

		def name()
			return "kav"
		end

		def hname()
			return "KAV (key assignment value)"
		end

		def help()
			intro_msg = "Search for the given keywords. Thus they must be given
on the command line."
			example_msg = '{ :keywords => ["takeme", "grepmyval"] }'
			return HelpMessage.new(default_args, intro_msg , example_msg, "")
		end
	end

end
