
##
# Pseudo base class for modules
#
# Modules process an input string, extract information
# and return a string, which is the input string for the
# next module.
module MCollectorModule

	class Base

		##
		# Process string data
		# - opt_args = Hash
		#   - must have opt_args = { :prune => true or false, ... }
		#     - prune = bool: if true return input_str without the
		#       extracted data. Otherwise return input_str untouched
		# - return [list_of_hashes, maybe_mod_input_str]
		#
		# The list of hashes contains one entry for one line in the
		# resulting CSV file. E.g. moduleA returns 3 row hashes and
		# moduleB returns 2 row hashes on stringC. Thus for stringC we
		# have 2 * 3 = 6 rows in the resulting CSV file.

		def apply(input_str, opt_args = {})
			raise NotImplementedError, "Implement apply() method in child class"
		end

		##
		# Return name as string

		def name()
			raise NotImplementedError, "Implement name() method in child class"
		end

		##
		# Return help message as string

		def help()
			raise NotImplementedError, "Implement help() method in child class"
		end

	end

end
