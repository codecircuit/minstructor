require_relative './base.rb'
require_relative './kav.rb'

module MCollectorModule

	##
	# Automated Key Assignment Value Module
	#
	# Searches automatically for KEY ASSIGNMENTSYMBOL VALUE patterns

	class AKAV < Base
		def apply(input_str, opt_args)

			# TODO: currently we also remove the keys
			# which are ignored from the string. It would be more
			# reasonable to keep the ignored keywords, to be able
			# to process them in a subsequent module.

			opt_args = {
				:nokeywords => [],
				:prune => true,
			}.merge(opt_args)

			get_md = ->(str) {
				return str.match(getKeyValueReg)
			}

			pruned_str = input_str.clone

			md = get_md.call(pruned_str) # call from kav module
			row = {}
			# Now we search iteratively for matching key value expressions.
			# In each step we delete the string part with the match.
			while md != nil
				val = md["value"]
				key = md["keyword"]
				if !opt_args[:nokeywords].include?(key) # ignore some keys
					row[key] = val
				end
				pruned_str = md.pre_match + md.post_match # remove match from str
				md = get_md.call(pruned_str)
			end

			return [[row], opt_args[:prune] ? pruned_str : input_str]
		end

		def name()
			return "akav"
		end

		def help()
			return ' :nokeywords => ["ignorethis", "alsoignorethis"],
			:prune => true # prune the string for the next module'
		end
	end

end
