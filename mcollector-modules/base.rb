
##
# Pseudo base class for modules
#
# Modules process an input string, extract information
# and return a string, which is the input string for the
# next module.
module MCollectorModule

	class DefaultArgs
		##
		# args_with_help_message = { :keywords => [["default0", "default1" ], "This is the long explanation of the keywords argument"]}
		def initialize(args_with_help_message)
			if args_with_help_message.class != Hash
				raise ArgumentError, "DefaultArgs can only be initialized with a Ruby Hash object"
			end
			args_with_help_message.each do |k, v|
				if v.class != Array
					raise ArgumentError, "DefaultArgs must be given a Hash with a tuple as values"
				end
				if v.length != 2
					raise ArgumentError, "DefaultArgs must be given a Hash with a tuple as values"
				end
				if v[1].class != String
					raise ArgumentError, "DefaultArgs needs a Hash with a tuple as values which has a string as second parameter"
				end
			end
			@args_with_help_message = args_with_help_message.clone
		end

		def merge(curr_args)
			default_args = {}
			@args_with_help_message.each do |k, val_and_helpmsg|
				default_args[k] = val_and_helpmsg[0]
			end

			return default_args.merge(curr_args)
		end

		def each
			@args_with_help_message.each do |k, tuple|
				yield(k, tuple[0], tuple[1])
			end
		end
	end

	class HelpMessage
		def initialize(default_args, intro, example, outro)
			@texts = {}
			@texts[:intro] = intro
			@texts[:outro] = outro
			@texts[:example] = example
			@dargs = default_args
		end

		def format_dargs
			str = ""
			@dargs.each do |k, default_value, helpmsg|
				str += " - hashkey: `" + (k.class == Symbol ? ":" : "") + k.to_s + "`\n"
				str += "   default: `" + default_value.to_s + "`\n"
				str += "   explanation: " + helpmsg + "\n\n"
			end
			return str
		end
		def get_texts
			return @texts
		end
		def get_dargs
			return @dargs
		end
	end

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
		# Return human readable name as string
		def hname()
			raise NotImplementedError, "Implement hname() method in child class"
		end

		##
		# Return help message as string

		def help()
			raise NotImplementedError, "Implement help() method in child class"
		end

	end
end

def puts(help_message)
	if help_message.class == MCollectorModule::HelpMessage
		puts ""
		puts help_message.get_texts[:intro]
		puts ""
		if !help_message.format_dargs.empty?
			puts "## Arguments"
			puts ""
			puts help_message.format_dargs
		end
		if !help_message.get_texts[:example].empty?
			puts "## Example"
			puts ""
			puts help_message.get_texts[:example]
			puts ""
		end
		if !help_message.get_texts[:outro].nil?
			if !help_message.get_texts[:outro].empty?
				puts help_message.get_texts[:outro]
				puts ""
			end
		end
	else
		super(help_message)
	end
end
