#!/usr/bin/ruby

require 'optparse'
require 'ostruct'
require 'pp'

# Install it via ruby gems
require 'progressbar'

class OptparseExample

	def self.parse(args)
		# The options specified on the command line will be collected in
		# *options*. We set default values here.
		options = OpenStruct.new
		options.verbose = false
		options.debug = false
		options.cmd = ""
		options.dry = false
		options.opath = ""
		options.backend = :shell
		options.noprompt = false
		options.rep = 1 # number of command repetitions

		opt_parser = OptionParser.new do |opts|
			opts.banner = "Usage: minstructor.rb [options]"

			opts.separator ""
			opts.separator "Mandatory:"

			opts.on("-c", '--cmd "/path/to/binary [<key> {<val>|<range>}]"',
			        "You can specify ranges on various ways, e.g.:",
			        "* [4,a,8,...]           simple lists",
			        "* range(0,20,3)         python-like ranges",
			        "* linspace(0,2,5)       numpy-like linear ranges",
			        "* logspace(1,1000,5,10) numpy-like log ranges",
			        'E.g. -c "./binary -k0 foo -k1 range(3) -k2 [a,b]"') do |cmd|
				options.cmd = cmd
			end

			opts.on("-n <repetitions>", "Number every unique command is repeated") do |rep|
				options.rep = rep.to_i()
			end

			opts.on("-o", "--output-dir <pth/to/output/personal_prefix_>",
			        "Directory where all output files, which contain the stdout of",
			        "your binary, will be saved") do |p|
				options.opath = p
			end

			opts.separator ""
			opts.separator "Optional:"

			opts.on("-f", "Do not prompt. Be careful with this flag!") do |noprompt|
				options.noprompt = noprompt
			end

			opts.on("-b", "--backend [slurm|shell]",[:slurm, :shell],
			        "DEFAULT=shell; Where to execute your binary. E.g. if you want to leave",
			        "an ssh session after starting the minstructor.rb, you can execute the",
			        "script within a byobu environment and take the 'shell' backend.",
			        "In case of the slurm backend, jobs will be sent via sbatch") do |b|
				options.backend = b
			end

			opts.on("-a", '--backend-args "<args>"',
			        'E.g. -a "--exclusive -w <hostname>" for slurm') do |ba|
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
			opts.on_tail("-v", "--[no-]verbose", "Run verbosely") do |v|
				options.verbose = v
			end

			# Boolean switch.
			opts.on_tail("-d", "--[no-]debug", "Debug mode; includes verbosity") do |d|
				options.debug = d
			end

			# Boolean switch.
			opts.on_tail("--dry-run", "Just print all commands which would be executed") do |dr|
				options.dry = dr
			end

		end

		opt_parser.parse!(args)
		options
	end  # parse()

end  # class OptparseExample

$options = OptparseExample.parse(ARGV)
# if debug be also verbose
$options.verbose = $options.verbose || $options.debug

def debug(msg)
	puts "#{msg}" if $options.debug
end

# You must remove white spaces before using this dictionary
floatingPointRegex = /[-+]?[[:digit:]]*\.?[[:digit:]]*/
integerRegex       = /[-+]?[[:digit:]]+/

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
	return (s...e).step(i).to_a
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
	for i in (0...num-1)
		res.push(acc.round(precision))
		acc += step
	end

	return res
end

# start, end, number of values, base, floating point precision
# numpy like logspace
def logspace(s, e, num=50, base=10.0, precision=6)
	exponents = linspace(s, e, num)
	return exponents.map { |exp| (base**exp).round(precision) }
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
		list.each_index { |i| 
			if list[i].class == Array
				list[i].each { |e|
					copy = Array.new(list)
					copy[i,1] = e
					res.push(copy)
				}
				return res
			end
		}
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

$regexOfRangeExpr = {
# I want to group without capturing as the String.scan function
# works than as expected. E.g. "[a,b,33]".scan(/\[(.+,)+.+\]/) = [["a,b,"]]
# which is not what I want. Using the paranthesis with (?:<rest of pattern>)
# solves the problem. See also `ri Regexp` chapter Grouping
	:list   => /\[\s*(?:[^,\s]+\s*,\s*)+[^,\s]+\s*\]/,
	:range1 => /range\(\s*#{integerRegex}\s*\)/,
	:range2 => /range\(\s*#{integerRegex}\s*,\s*#{integerRegex}\s*\)/,
	:range3 => /range\(\s*#{integerRegex}\s*,\s*#{integerRegex}\s*,\s*#{integerRegex}\s*\)/,
	:linspace2 => /linspace\(\s*#{floatingPointRegex}\s*,\s*#{floatingPointRegex}\s*\)/,
	:linspace3 => /linspace\(\s*#{floatingPointRegex},\s*#{floatingPointRegex}\s*,\s*#{floatingPointRegex}\s*\)/,
	:logspace2 => /logspace\(\s*#{floatingPointRegex}\s*,\s*#{floatingPointRegex}\s*\)/,
	:logspace3 => /logspace\(\s*#{floatingPointRegex}\s*,\s*#{floatingPointRegex}\s*,\s*#{floatingPointRegex}\s*\)/,
	:logspace4 => /logspace\(\s*#{floatingPointRegex}\s*,\s*#{floatingPointRegex}\s*,\s*#{floatingPointRegex}\s*,\s*#{floatingPointRegex}\s*\)/,
}

def identifyRangeExpr(str)
	str.gsub!(/\s/, '')
	$regexOfRangeExpr.each do |key, regex|
		return key if str.index(regex) != nil
	end
	return nil
end

# Takes one string and returns a list of strings
# if the input string has been a range expression.
# E.g. "-key0"    -> "-key0"
#      "range(3)" -> ["0", "1", "2"]
def expandRangeExpr(str)
	str.gsub!(/\s/, '')
	type = identifyRangeExpr(str)
	if  type != :list and type != nil # :list is a self defined type (see above)
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
	debug("ENTERED THE FRONTEND WITH USER INPUT = #{userInput}")
	if userInput.empty?
		puts "You have not specified a command!"
		exit
	end

	# First we search for all regex matches and expand them.
	# The expansion is linked to the match. E.g.
	# User Input = "-key0 val0 -key1 range(2) -key2 range(4,6) -key3 range(4,6)"
	# matchToExpansion = {"range(2)" => [0, 1], "range(4,6)" => [4, 5]}
	# We can not search for the expansion patterns and replace
	# them immediately, as we would change the underlaying container
	# while iterating over it, which results in undefined behaviour.
	matchToExpansion = {}
	$regexOfRangeExpr.each_pair do |k,reg|
		debug("CHECKING THE KEY #{k} WITH REGEX #{reg}")
		if k != :list # lists must be treated separately
			strRanges = userInput.scan(reg)
			debug("SCAN PATTERN RESULT #{strRanges}")
			strRanges.each do |strRange|
				debug("TRY TO EVAL #{strRange}")
				expRange = eval(strRange)
				matchToExpansion[strRange] = expRange
			end
		else # if it is a list
			strLists = userInput.scan(reg)
			debug("LISTS I FOUND = #{strLists}")
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
	matchToExpansion.each_pair { |k,v|
		partitioned.map!{ |e|
			partitionAll.call(e, k)
		}
		debug("MATCH TO EXPANSION #{k} => #{v}")
		partitioned.replace(partitioned.flatten())
	}

	# Now we want to replace the collected expansions
	expanded = partitioned
	expanded.map! do |cmdPart|
		# replace or change nothing if hash does not contain the cmdPart
		matchToExpansion.fetch(cmdPart, cmdPart)
	end

	debug("THE FRONTEND RETURNS #{expanded}")
	return expanded
end

###########
# BACKEND #
###########
# help function
def expandTilde(path)
	return path.gsub(/~/, %x(printf $HOME))
end

def generateCmds(expandedCmds, opath="", backend=:shell)
	# Here we generate the commands for the specified backend
	validBackends = [:shell, :slurm]
	if not (validBackends.include?(backend))
		puts "ERROR: backend #{backend} is not supported yet!"
		exit
	end

	puts "COMMAND GENERATOR GOT #{expandedCmds}" if $options.debug

	expandedCmds = combinations(expandedCmds)
	expandedCmds.map! { |cmd| cmd.join() }

	puts "COMMAND EXPANDED CMDS LIST TO #{expandedCmds}" if $options.debug

	## REPEAT COMMANDS IF WANTED ##
	puts "Number of repetitions = #{$options.rep}" if $options.debug
	expandedCmds = expandedCmds * $options.rep
	puts "COMMANDS AFTER REPETITIONS #{expandedCmds}" if $options.debug

	# OUTPUT FILE NAMING
	# 1. if /output/path is a directory then name the output files
	#    /output/path/output_0.txt, /output/path/output_1.txt,...
	# 2. if output path = /foo/bar/myprefix and /foo/bar/myprefix does not
	#    exist, but /foo/bar is a directory then name the output files
	#    /foo/bar/myprefix_0.txt, /foo/bar/myprefix_1.txt,...
	outputFiles = []
	if not opath == ""
		i = -1 # simply enumerate output files
		expandedCmds.map do |cmd|
			outputFilePath = String.new(opath)
			if File.directory?(opath)
				outputFilePath = outputFilePath.chomp('/') + '/out_' 
			else # else the user gave a prefix for the output files on the command line
				outputFilePath << '_'
			end
			i += 1
			outputFilePath << i.to_s + ".txt"
			# expand ~ to home directory
			outputFilePath = expandTilde(outputFilePath)
			outputFiles.push(outputFilePath)
		end
	end

	puts "GENERATED #{outputFiles.length} OUTPUT FILE NAMES" if $options.debug

	## ADJUST COMMANDS FOR BACKEND AND MERGE WITH OUTFILES ##
	if backend == :slurm
		puts "BACKEND SLURM!!" if $options.debug
		expandedCmds.each_with_index do |cmd, i|
			cmd = "sbatch " + "#{$options.backendArgs} " + '--wrap "' + cmd + '"'
			cmd << " -o #{outputFiles[i]}" unless outputFiles.empty?
			expandedCmds[i] = cmd
		end
	end
	if backend == :shell
		puts "BACKEND SHELL!!" if $options.debug
		outputFiles.each_with_index do |outFile, i|
			expandedCmds[i] += " > #{outFile}"
		end
	end

	if expandedCmds.empty?
		puts "ERROR: no commands have been created! Check your syntax!"
		exit 1
	end

	# REMOVE UNNECESSARY WHITESPACE
	expandedCmds.map! { |cmd| cmd.squeeze(" ") }

	linesShowMax = 15
	if expandedCmds.length() > linesShowMax and not $options.verbose
		puts "Here is an random excerpt of your in total #{expandedCmds.length()} generated commands:"
		expandedCmds.sample(linesShowMax).each { |cmd| puts cmd }
	else
		puts "The Measurement Instructor generated the following commands for you:"
		expandedCmds.each { |cmd| puts cmd }
	end


	# CHECK CONSISTENCY OF OUTPUT FILES
	promped = false
	if outputFiles.size != 0
		if outputFiles.any? { |ofile| File.exists?(ofile) } and not $options.noprompt
			print "CAUTION: some output files will be overwritten if you proceed. Continue? [y/N]: "
			answer = gets.chomp
			if not %w[Yes Y y yes].any? {|key| answer == key}
				puts "Going to exit..."
				exit
			end
			promped = true
		end
		if not File.directory?(outputFiles[0].split('/')[0...-1].join('/'))
			puts "ERROR: your output directory does not exist! Create it first!"
			exit
		end
	end

	if not promped and not $options.noprompt
		print "Do you really want to execute the generated commands? [y/N]: "
		answer = gets.chomp
		if not %w[Yes Y y yes].any? {|key| answer == key}
			puts "Going to exit"
			exit
		end
	end
	puts "Continue..."
	return expandedCmds
end

##################################
# EXECUTE THE GENERATED COMMANDS #
##################################
def executeCmds(cmds)
	# If not verbose we want to have a progressbar
	if not $options.verbose
	pbar = ProgressBar.create()
	pbar.total = cmds.length
	# pbar.title = <title> # to set the title of the progressbar
	end

	cmds.each do |cmd|
		puts "Executing: '#{cmd}'" if $options.verbose
		%x(sleep 0.5) if $options.backend == :slurm
		%x(#{cmd}) unless $options.dry
		pbar.increment() unless $options.verbose
	end
	puts "Nothing has been executed; this has been a dry run" if $options.dry
end

if __FILE__ == $0
	cmd = frontend($options.cmd)
	expanded_cmds = generateCmds([cmd], $options.opath, $options.backend)
	executeCmds(expanded_cmds)
end
