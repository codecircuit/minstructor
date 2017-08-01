#!/usr/bin/ruby

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
		options.backend = :shell
		options.noprompt = false
		options.rep = 1 # number of command repetitions

		opt_parser = OptionParser.new do |opts|
			opts.banner = 'Usage: minstructor.rb [OPTIONS] "CMD0" "CMD1"'

			opts.separator ""
			opts.separator "Options:"

			opts.on("-n NUM", "Number every unique command " \
			                            "is repeated") do |rep|
				options.rep = rep.to_i
			end

			opts.on("-o", "--output-dir DIR[/PREFIX]",
			        "Directory where all output files, which contain",
			        "the stdout of your binary, will be saved") do |p|
				options.opath = p
			end

			opts.on("-f", "Do not prompt") do |noprompt|
				options.noprompt = noprompt
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

# Between submitting jobs the script makes a break
# of SLURMDELAY seconds. This prevents slurm from
# rejecting jobs
$SLURMDELAY = 0.5

def DEBUG(msg)
	puts "#{msg}" if $options.debug
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

	res = [s]
	step = (e - s) / (num - 1.0)
	acc = s + step
	(0...num-1).each do
		res.push(acc.round(precision))
		acc += step
	end

	res
end

# start, end, number of values, base, floating point precision
# numpy like logspace
def logspace(s, e, num=50, base=10.0, precision=6)
	exponents = linspace(s, e, num)
	exponents.map { |exp| (base**exp).round(precision) }
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
	containsArray = ->(list) { list.any? { |el| el.class == Array } }

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
}

def identifyRangeExpr(str)
	str.gsub!(/\s/, '')
	$regexOfRangeExpr.each do |key, regex|
		return key if str.index(regex) != nil
	end

	nil
end

# Takes one string and returns a list of strings
# if the input string has been a range expression.
# E.g. "-key0"    -> "-key0"
#      "range(3)" -> ["0", "1", "2"]
def expandRangeExpr(str)
	str.gsub!(/\s/, '')
	type = identifyRangeExpr(str)
	if  type != :list && type != nil # :list is a self defined type (see above)
		values = eval(str)
		return values.map { |el| el.to_s }
	elsif type == :list
		# add quotation marks around list elements
		return eval(str.gsub!(/([^\[\],]+)/,'\'\1\''))
	else
		return str
	end
end

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
		if k != :list # lists must be treated separately
			strRanges = userInput.scan(reg)
			DEBUG("SCAN PATTERN RESULT #{strRanges}")
			strRanges.each do |strRange|
				DEBUG("TRY TO EVAL #{strRange}")
				expRange = eval(strRange)
				matchToExpansion[strRange] = expRange
			end
		else # if it is a list
			strLists = userInput.scan(reg)
			DEBUG("LISTS I FOUND = #{strLists}")
			strLists.each do |strList|
				# convert to a real list
				# e.g. '[a,b,33]' --> ['a','b','33']
				# Add quotation marks around elements
				l = eval(strList.gsub(/([^\[\],]+)/,'\'\1\''))
				matchToExpansion[strList] = l
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
end

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
		if opath.empty?
			@prefix = nil
			@id = nil
			DEBUG("  - created an empty file name iterator object")
			DEBUG("[-] OutputFileNameIterator()")
			return
		end

		## SETTING THE PREFIX ##
		@prefix = String.new(opath)
		if File.directory?(opath)
			outDir = opath
			@prefix = "#{@prefix.chomp('/')}/out_"
			DEBUG("  - I got a output directory from the CLI")
		else # else the user gave a prefix for the output files on the command line
			outDir = File.dirname(opath)
			if not File.directory?(outDir)
				raise IOError, "Your output directory #{outDir} does not exists!"
			end
			DEBUG("  - I got a prefix for the output file naming on the CLI")
		end

		## SETTING THE OUTPUT FILE INDEX ##
		DEBUG("  - Search for the first free output file index")
		DEBUG("    to prevent a file overwrite...")
		@prefix = File.expand_path(@prefix)
		@prefix.freeze
		DEBUG("  - prefix = #{@prefix}")
		outFileReg = /#{File.basename(@prefix)}(#{$integerRegex})\.txt/
		usedIndices = [-1] # -1 results in default start index of 0
		DEBUG("  - checking files in #{outDir}")
		Dir.foreach(outDir) do |dirMem|
			DEBUG("    - checking dir member = #{dirMem}")
			if File.file?("#{outDir}/#{dirMem}")
				md = dirMem.match(outFileReg)
				if md != nil
					DEBUG("    - match data = #{md}")
					usedIndices += [md[1].to_i]
				end
			end
		end
		if system("which scontrol > /dev/null 2>&1")
			DEBUG("  - checking scheduled slurm output files")
			scontrol_out = `scontrol show job -u $(whoami)`
			reg = /(?<=StdErr=).*|(?<=StdOut=).*/
			user_out_files = scontrol_out.scan(reg)
			user_out_files.each do |f|
				DEBUG("    - checking if #{f} in #{outDir}")
				md = f.match(outFileReg)
				if md != nil
					DEBUG("      - #{f} increases the first index")
					usedIndices += [md[1].to_i]
				end
			end
		end
		@id = usedIndices.max + 1
		DEBUG("  - uses start index = #{@id}")
		DEBUG("[-] OutputFileNameIterator()")
	end # end initialize

	def empty?
		@prefix == nil
	end

	def next
		return "" if @prefix == nil
		currOutFilePath = @prefix + @id.to_s + ".txt"
		@id += 1

		currOutFilePath
	end
end

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

	parsedCmds = combinations(parsedCmds)
	parsedCmds.map! { |cmd| cmd.join }

	DEBUG("  - cmds after combinations #{parsedCmds}")

	## REPEAT COMMANDS IF WANTED ##
	DEBUG("  - Number of repetitions = #{$options.rep}")
	parsedCmds = parsedCmds * $options.rep
	DEBUG("  - cmds with repititions = #{parsedCmds}")


	## ADJUST COMMANDS FOR BACKEND AND APPEND OUTFILES ##
	if backend == :slurm
		DEBUG("  - you choose the slurm backend")
		parsedCmds.map! do |cmd|
			cmd = "sbatch #{$options.backendArgs} " + '--wrap "' + cmd + '"'
			cmd << " -o #{outFileName_it.next}" unless outFileName_it.empty?
			cmd
		end
	end
	if backend == :shell
		DEBUG("  - you choose the shell backend")
		if not outFileName_it.empty?
			parsedCmds.map! do |cmd|
				cmd += " > #{outFileName_it.next}"
			end
		end
	end

	if parsedCmds.empty?
		STDERR.puts "ERROR: no commands have been created! Check your syntax!"
		exit 1
	end

	# REMOVE UNNECESSARY WHITESPACE
	parsedCmds.map! { |cmd| cmd.squeeze(" ") }

	DEBUG("[-] expandCmd()")
	parsedCmds
end

##################################
# EXECUTE THE GENERATED COMMANDS #
##################################
def executeCmds(cmds)
	# If not verbose we want to have a progressbar
	if not $options.verbose
	pbar = ProgressBar.create
	pbar.total = cmds.length
	# pbar.title = <title> # to set the title of the progressbar
	end

	cmds.each do |cmd|
		puts "Executing: '#{cmd}'" if $options.verbose
		`sleep #{$SLURMDELAY}` if $options.backend == :slurm
		`#{cmd}` unless $options.dry
		pbar.increment unless $options.verbose
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
		if $options.backend == :slurm
			estSec = expandedCmds.length * $SLURMDELAY
			if estSec / 3600.0 > 24.0
				puts "Submitting the jobs will take more than 24h."
			else
				t = Time.new(0)
				t += estSec
				puts "The jobs will approximately be submitted in " \
				     "#{t.strftime("%T")} (hh:mm:ss)"
			end
		end
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
			exit
		end
		puts "Continue..."
	end

	executeCmds(expandedCmds)
end
