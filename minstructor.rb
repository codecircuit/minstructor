#!/usr/bin/env ruby

require 'optparse'
require 'ostruct'

# Install it via ruby gems
require 'progressbar'

class OptPrs

	def self.parse(args)
		# The options specified on the command line will be collected in
		# *options*. We set default values here.
		options = OpenStruct.new
		options.verbose = false
		options.debug = false
		options.dry = false
		options.opath = ""
		options.vfnames = false
		options.backend = :shell
		options.noprompt = false
		options.rep = 1 # number of command repetitions
		options.job_delay = 0.5 # seconds between two job submissions
		options.disable_progress_bar = false
		options.backendArgs = ""

		opt_parser = OptionParser.new do |opts|
			opts.banner = 'Usage: minstructor.rb [OPTIONS] "CMD0" "CMD1"'

			opts.separator ""
			opts.separator "Options:"

			opts.on("-n NUM", "Number every unique command " \
			                            "is repeated") do |rep|
				options.rep = rep.to_i
			end

			opts.on("-t SECONDS", "Seconds between two job submissions. " \
			        "Has an effect if some scheduler is chosen as back end.") do |rep|
				options.job_delay = rep.to_f
			end

			opts.on("-o", "--output-dir DIR[/PREFIX]",
			        "Directory where all output files, which contain",
			        "the stdout of your binary, will be saved") do |p|
				options.opath = p
			end

			opts.on("--verbose-fnames",
			        "Add suffix with current command line parameters",
			        "to output file names") do |vfnames|
				options.vfnames = vfnames
			end

			opts.on("-f", "Do not prompt") do |noprompt|
				options.noprompt = noprompt
			end

			opts.on("--no-progress-bar", "Hide the progress bar") do |disable_progress_bar|
				# we must invert here, as the CLI parser interprets the `--no-...`
				# pattern and sets the variable `disable_progress_bar` to false
				# if `--no-progressbar` arises as CL flag
				options.disable_progress_bar = (not disable_progress_bar)
			end


			opts.on("-b", "--backend [slurm|shell]",[:slurm, :shell],
			        "DEFAULT=shell; Where to execute your binary. E.g.",
			        "if you want to leave an ssh session after starting",
			        "the minstructor.rb, you can execute the script",
			        "within a byobu environment and take the 'shell'",
			        "backend. In case of the slurm backend, jobs will",
			        "be sent via sbatch") do |b|
				options.backend = b
			end

			opts.on("-a", '--backend-args "ARGS"',
			        'E.g. "--exclusive -w HOST" for slurm') do |ba|
				options.backendArgs = ba
			end

			opts.separator ""
			opts.separator "Common:"

			# No argument, shows at tail.  This will print an options summary.
			# Try it and see!
			opts.on_tail("-h", "--help", "Show this message") do
				puts opts
				exit
			end

			# Boolean switch.
			opts.on_tail("-v", "--verbose", "Run verbosely") do |v|
				options.verbose = v
			end

			# Boolean switch.
			opts.on_tail("-d", "--debug", "Debug mode; includes verbosity") do |d|
				options.debug = d
			end

			# Boolean switch.
			opts.on_tail("--dry-run", "Just print all commands, which would " \
			             "be executed") do |dr|
				options.dry = dr
			end

		end

		opt_parser.set_summary_indent("  ")
		opt_parser.set_summary_width(20)
		opt_parser.parse!(args)
		options
	end  # parse()
end  # class OptPrs

$options = OptPrs.parse(ARGV)
$options.cmds = ARGV # parse mandatory args

# if debug be also verbose
$options.verbose = $options.verbose || $options.debug

def DEBUG(msg)
	puts "#{msg}" if $options.debug
end

class Float
	def try_int(epsilon = 0.0)
		self == 0.0 ? 0 : ((to_i() - self) / self).abs <= epsilon ? to_i() : self
	end
end

###################
# RANGE FUNCTIONS #
###################

# start, end, increment
# endpoint is excluded
# python like range
def range(s, e=nil, i=1)
	return (0..s-1).step(i).to_a if e == nil

	if e <= s
		raise RangeError, "I can not expand range, because end <= start"
	end

	i = i.round
	(s...e).step(i).to_a
end

# start, end, num values, floating point precision
# endpoint is always included
# numpy like linspace
def linspace(s, e, num=50, precision=12)
	if num <= 0
		raise RangeError, "number of logspace values equals to zero"
	end

	return [s] * num if s == e

	epsilon = 10**(-precision)

	res = [s]
	step = (e - s) / (num - 1.0)
	acc = s + step
	(0...num-1).each do
		res.push(acc.round(precision).to_f().try_int(epsilon))
		acc += step
	end

	res
end

# start, end, number of values, base, floating point precision
# numpy like logspace
def logspace(s, e, num=50, base=10.0, precision=6)
	exponents = linspace(s, e, num)
	epsilon = 10**(-precision)
	exponents.map { |exp| (base**exp).round(precision).to_f().try_int(epsilon) }
end

def fromfile(filename)
	res = []
	File.open(filename) do |f|
		f.each_line do |l|
			res.push(l.chomp())
		end
	end
	res
end

##############################
# COMMAND BUILDING FUNCTIONS #
##############################
# these functions build all
# wanted combinations given
# by the command line args.

# takes a list [a, [b, c], 0, [3, 4], d]
# and returns all possible combinations
#   - [a, b, 0, 3, d]
#   - [a, b, 0, 4, d]
#   - [a, c, 0, 3, d]
#   - [a, c, 0, 4, d]
def combinations(l)

	# This helper function takes a list
	# [a, [c, d], e, [7, 8]] and expands
	# the first bracket within the list to
	# [[a, c, e, [7, 8]], [a, d, e, [7,8]]]
	expand = ->(list) {
		res = []
		list.each_index do |i| 
			if list[i].class == Array
				list[i].each do |e|
					copy = Array.new(list)
					copy[i, 1] = e
					res.push(copy)
				end
				return res
			end
		end
	}

	# Helper function which returns true if there is
	# still sth to expand
	# [bin, c, b, 3] -> false
	# [bin, [a,c], b, 3] -> true
	containsArray = ->(list) { list.class == Array ? list.any? { |el| el.class == Array } : false }

	# Check first if there is work left
	if l.any? { |list| containsArray.call(list) }
		# If Yes: expand something
		l.map! { |list| expand.call(list) }
		# Is there still something to expand?
		# then call recursively
		if l.any? { |list| containsArray.call(list) }
			return combinations(l.flatten(1)) 
		else
			return l.flatten(1)
		end
	else
		return l
	end
end

############
# FRONTEND #
############
# The task of the frontend is to detect pre-defined range expressions and to
# replace them with their appropriate expanded lists.

# You must remove white spaces before using this dictionary
$floatingPointRegex = /[-+]?[[:digit:]]*\.?[[:digit:]]*/
$integerRegex       = /[-+]?[[:digit:]]+/
#$pathRegex          = /[^[:space]]+/
$pathRegex          = /[^[:space:]\(\)]+/

$regexOfRangeExpr = {
# I want to group without capturing as the String.scan function
# works than as expected. E.g. "[a,b,33]".scan(/\[(.+,)+.+\]/) = [["a,b,"]]
# which is not what I want. Using the paranthesis with (?:<rest of pattern>)
# solves the problem. See also `ri Regexp` chapter Grouping
	:list   => /\[\s*(?:[^,\s]+\s*,\s*)+[^,\s]+\s*\]/,
	:range1 => /range\(\s*#{$integerRegex}\s*\)/,
	:range2 => /range\(\s*#{$integerRegex}\s*,\s*#{$integerRegex}\s*\)/,
	:range3 => /range\(\s*#{$integerRegex}\s*,\s*#{$integerRegex}\s*,\s*#{$integerRegex}\s*\)/,
	:linspace2 => /linspace\(\s*#{$floatingPointRegex}\s*,\s*#{$floatingPointRegex}\s*\)/,
	:linspace3 => /linspace\(\s*#{$floatingPointRegex},\s*#{$floatingPointRegex}\s*,\s*#{$floatingPointRegex}\s*\)/,
	:logspace2 => /logspace\(\s*#{$floatingPointRegex}\s*,\s*#{$floatingPointRegex}\s*\)/,
	:logspace3 => /logspace\(\s*#{$floatingPointRegex}\s*,\s*#{$floatingPointRegex}\s*,\s*#{$floatingPointRegex}\s*\)/,
	:logspace4 => /logspace\(\s*#{$floatingPointRegex}\s*,\s*#{$floatingPointRegex}\s*,\s*#{$floatingPointRegex}\s*,\s*#{$floatingPointRegex}\s*\)/,
	:fromfile => /fromfile\(\s*#{$pathRegex}\s*\)/,
}

# The frontend takes the cmd input with range expressions
# E.g. "./bin -key0 val -key1 range( 3) -key2 [a,b,33] foo"
# and searches for the range expressions defined by regex expressions.
# The matched patterns will be expanded to their appropriate ranges
# and the frontend returns a list like
# Output = ["./bin -key0 val -key1 ", [0,1,2], " -key2 ", ['a','b','33'], "foo"]
def frontend(userInput)
	DEBUG(" ")
	DEBUG("[-] frontend()")
	DEBUG("  - input = #{userInput}")
	# First we search for all regex matches and expand them.
	# The expansion is linked to the match. E.g.
	# User Input = "-key0 val0 -key1 range(2) -key2 range(4,6) -key3 range(4,6)"
	# matchToExpansion = {"range(2)" => [0, 1], "range(4,6)" => [4, 5]}
	# We can not search for the expansion patterns and replace
	# them immediately, as we would change the underlaying container
	# while iterating over it, which results in undefined behaviour.
	matchToExpansion = {}
	$regexOfRangeExpr.each_pair do |k, reg|
		DEBUG("CHECKING THE KEY #{k} WITH REGEX #{reg}")
		if k == :list
			strLists = userInput.scan(reg)
			DEBUG("LISTS I FOUND = #{strLists}")
			strLists.each do |strList|
				# convert to a real list
				# e.g. '[a,b,33]' --> ['a','b','33']
				# Add quotation marks around elements
				l = eval(strList.gsub(/([^\[\],]+)/,'\'\1\''))
				matchToExpansion[strList] = l
			end
		elsif k == :fromfile
			# Here we also add quotation marks
			strRanges = userInput.scan(reg)
			DEBUG("SCAN PATTERN RESULT #{strRanges}")
			strRanges.each do |strRange|
				DEBUG("CURRENT REGEX = #{$regexOfRangeExpr[:fromfile]}")
				DEBUG("strRange = #{strRange}")
				r = /fromfile\(\s*(?<path>#{$pathRegex})\s*\)/
				m = strRange.scan(r)
				DEBUG("EVALUATING fromfile(#{m[0][0]})")
				expRange = fromfile(m[0][0])
				DEBUG("Adding #{expRange} FROMFILE")
				matchToExpansion[strRange] = expRange
			end
		else # all other stuff
			strRanges = userInput.scan(reg)
			DEBUG("SCAN PATTERN RESULT #{strRanges}")
			strRanges.each do |strRange|
				DEBUG("TRY TO EVAL #{strRange}")
				expRange = eval(strRange)
				DEBUG("Adding #{expRange}")
				matchToExpansion[strRange] = expRange
			end
		end
	end

	# built-in partition function splits the string at the
	# first occurance of word. But this functions splits at
	# every occurance of word. E.g.
	# Input =  ["this is foo and another foo but bar"]
	# If we split at word 'foo' this results in
	# Output = ["this is ", "foo", " and another ", "foo", " but bar"]
	partitionAll = ->(str, word) {
		f, m, t = str.partition(word)
		return ""   if str == ""
		return f    if m == ""
		return f, m if t == ""
		return f, m, partitionAll.call(t, word)
	}

	# Now we partition the user command at the point of
	# pre-defined range expressions. E.g.
	# Input = ["./bin -key0 bla -key1 range(3 ) -key2 [a,b,33 ]"]
	# Output = ["./bin -key0 bla -key1 ", "range(3 )", "-key2 ", "[a,b,33 ]"]
	partitioned = [userInput]
	matchToExpansion.each_pair do |k, v|
		partitioned.map! do |e|
			partitionAll.call(e, k)
		end
		DEBUG("MATCH TO EXPANSION #{k} => #{v}")
		partitioned.replace(partitioned.flatten)
	end

	# Now we want to replace the collected expansions
	expanded = partitioned
	expanded.map! do |cmdPart|
		# replace or change nothing if hash does not contain the cmdPart
		matchToExpansion.fetch(cmdPart, cmdPart)
	end

	DEBUG("  - Returns = #{expanded}")
	DEBUG("[-] frontend()")

	expanded
end # frontend

###########
# BACKEND #
###########

# This class determines the correct output file naming
# and represents an enumerator, which returns the current output
# file name. The output file names are enumerated consecutively,
# but without overwriting any existing file. This the first
# index is the first free index.
class OutputFileNameIterator
	def initialize(opath)
		DEBUG("[+] OutputFileNameIterator(opath=#{opath})")
		@created_dirs = []
		@out_file_prefix = "out_"
		if opath.empty?
			@prefix = nil
			@id = nil
			DEBUG("  - created an empty file name iterator object")
			DEBUG("[-] OutputFileNameIterator()")
			return
		end

		@out_dir_id = 0
		@out_dir_prefix = "minstructor_"
		if not Dir.exist?(opath.chomp('/'))
			Dir.mkdir(opath.chomp('/'))
			@created_dirs += [opath.chomp('/')]
		end
		@prefix = "#{opath.chomp('/')}/#{@out_dir_prefix}#{@out_dir_id}"
		while Dir.exist?(@prefix) do
			@out_dir_id += 1
			@prefix = "#{opath.chomp('/')}/#{@out_dir_prefix}#{@out_dir_id}"
		end
		Dir.mkdir(@prefix)
		@created_dirs += [@prefix]
		@prefix = File.expand_path(@prefix)
		@prefix += "/#{@out_file_prefix}"
		@prefix.freeze()

		## SETTING THE OUTPUT FILE INDEX ##
		DEBUG("  - Search for the first free output file index")
		DEBUG("    to prevent a file overwrite...")
		@prefix = File.expand_path(@prefix)
		@prefix.freeze
		DEBUG("  - prefix = #{@prefix}")
		@id = 0
		DEBUG("  - uses start index = #{@id}")
		DEBUG("[-] OutputFileNameIterator()")
	end # end initialize

	def empty?
		@prefix == nil
	end

	# remove created directories
	def rmdirs
		@created_dirs.reverse_each do |d|
			Dir.rmdir(d)
		end
	end

	def next(additional_suffix = "")
		#curr_out_file_path = ""
		return "" if @prefix == nil
		if additional_suffix == ""
			curr_out_file_path = @prefix + @id.to_s + ".txt"
		else
			curr_out_file_path = @prefix + @id.to_s + "_" +
				additional_suffix.strip().gsub(/\s/,"_") + ".txt"
		end
		@id += 1
		curr_out_file_path
	end
end # OutputFileNameIterator

# Takes the parsed command line e.g.:
#     ["./binary -k const -f ", [1,2,3], " foo bar"]
# and creates all commands from that e.g.:
#     ["./binary -k const -f 1 foo bar",
#      "./binary -k const -f 2 foo bar",
#      "./binary -k const -f 3 foo bar"]
# and applies backend specific modifications to the
# commands and repeats them if the user wants to execute
# the same commands more than once.
def expandCmd(parsedCmds, outFileName_it, backend=:shell)
	DEBUG(" ")
	DEBUG("[+] expandCmd()")
	# Here we generate the commands for the specified backend
	validBackends = [:shell, :slurm]
	if not (validBackends.include?(backend))
		puts "ERROR: backend #{backend} is not supported yet!"
		exit
	end

	DEBUG("  - input = #{parsedCmds}")

	# Save the positions of the variable parameters in the parsed
	#     command: ["foo", [1, 2], "bar", ["a", "b"]]
	#     parameter_pos: [1, 3]
	# This is used to create meaningful job and/or file names.
	# Add the index to the array elements first
	parameter_pos = parsedCmds[0].map.with_index { |v, i| [v, i] }
	# filter for Array positions
	DEBUG("  - parameter pos = #{parameter_pos}")
	parameter_pos.select!{ |x| x[0].class == Array }.map! { |x| x[1] }

	DEBUG("  - parsed Cmds before combinations = #{parsedCmds}")
	parsedCmds = combinations(parsedCmds)

	DEBUG("  - cmds after combinations #{parsedCmds}")

	## REPEAT COMMANDS IF WANTED ##
	DEBUG("  - Number of repetitions = #{$options.rep}")
	parsedCmds = parsedCmds * $options.rep
	DEBUG("  - cmds with repititions = #{parsedCmds}")

	## ADJUST COMMANDS FOR BACKEND AND APPEND OUTFILES ##
	if backend == :slurm
		DEBUG("  - you choose the slurm backend")
		parsedCmds.map! do |cmd|
			cmd_strs = []
			DEBUG("  - backendArgs = #{$options.backendArgs}")
			DEBUG("  - frontend(backendArgs) = #{frontend($options.backendArgs)}")
			DEBUG("  - combinations(frontend(backendArgs)) = #{combinations(frontend($options.backendArgs))}")
			combinations([frontend($options.backendArgs)]).each do |curr_backend_arg_list|
				curr_backend_args = curr_backend_arg_list.join()
				cmd_str = "sbatch #{curr_backend_args} " + "--wrap '" + cmd.join + "'"
				job_name = cmd.values_at(*parameter_pos).join("_")
				if $options.vfnames
					cmd_str << " -o #{outFileName_it.next(job_name)}" unless outFileName_it.empty?
				else
					cmd_str << " -o #{outFileName_it.next}" unless outFileName_it.empty?
				end
				cmd_str << " -J '#{job_name}' "
				cmd_strs += [cmd_str]
			end
			cmd_strs
		end
		DEBUG("  - parsedCmds before flatten = #{parsedCmds}")
		parsedCmds.flatten! #if $options.backendArgs != ""
	end
	if backend == :shell
		DEBUG("  - you choose the shell backend")
		if not outFileName_it.empty?
			parsedCmds.map! do |cmd|
				if $options.vfnames
					job_name = cmd.values_at(*parameter_pos).join("_")
					cmd_str = cmd.join + " > #{outFileName_it.next(job_name)}"
				else
					cmd_str = cmd.join + " > #{outFileName_it.next}"
					DEBUG("    - building up command: #{cmd_str}")
				end
				cmd_str
			end
		else 
			parsedCmds.map! { |cmd| cmd.join }
		end
	end

	if parsedCmds.empty?
		STDERR.puts "ERROR: no commands have been created! Check your syntax!"
		exit 1
	end

	DEBUG("  - parsed cmds befor sequeezing: #{parsedCmds}")
	# REMOVE UNNECESSARY WHITESPACE
	parsedCmds.map! { |cmd| cmd.squeeze(" ") }

	DEBUG("[-] expandCmd()")
	parsedCmds
end # expandCmd

##################################
# EXECUTE THE GENERATED COMMANDS #
##################################
def executeCmds(cmds)
	# If not verbose we want to have a progressbar
	DEBUG("disable progress bar = #{$options.disable_progress_bar}")
	if not $options.verbose and not $options.disable_progress_bar
		pbar = ProgressBar.create
		pbar.total = cmds.length
		# pbar.title = <title> # to set the title of the progressbar
	end

	cmds.each do |cmd|
		puts "Executing: '#{cmd}'" if $options.verbose
		if $options.backend == :slurm
			sleep($options.job_delay)
		end
		output = `#{cmd}` unless $options.dry
		puts("\n\n" + output + "\n") if $options.backend == :shell and $options.opath == ""
		pbar.increment if not $options.verbose and not $options.disable_progress_bar
	end
	puts "Nothing has been executed; this has been a dry run" if $options.dry
end

if __FILE__ == $0

	if $options.cmds.empty?
		puts "You have not specified any command!"
		exit
	end

	parsed = []
	$options.cmds.each do |cmd|
		parsed += [frontend(cmd)]
	end

	# Get output file naming
	outFileName_it = OutputFileNameIterator.new($options.opath)

	# expanded cmds is going to be a list of lists, each representing
	# the expansion of one command expression.
	expandedCmds = []
	parsed.each do |parsedCmd|
		expandedCmds += [expandCmd([parsedCmd], outFileName_it, $options.backend)]
	end

	linesShowMax = 15
	# flatten: [[cmd,cmd,...],[cmd,cmd,...]] -> [cmd,cmd,cmd,cmd,...]
	expandedCmds = expandedCmds.flatten
	if expandedCmds.length > linesShowMax && !$options.verbose
		puts "Here is an random excerpt of your in total " \
		     "#{expandedCmds.length} generated commands:"
		expandedCmds.sample(linesShowMax).each { |cmd| puts cmd }
	else
		puts "The Measurement Instructor generated the following commands for you:"
		expandedCmds.each { |cmd| puts cmd }
	end

	if not $options.noprompt
		print "Do you want to execute the generated commands? [y/N]: "
		# We need to clear the ARGV array, because `gets` does not
		# query for user input, if the array is still not empty
		ARGV.clear
		answer = gets.chomp
		if not %w[Yes Y y yes].any? {|key| answer == key}
			puts "Going to exit"
			outFileName_it.rmdirs()
			exit
		end
		puts "Continue..."
	end

	executeCmds(expandedCmds)
end
