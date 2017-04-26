#!/usr/bin/ruby

require 'optparse'
require 'ostruct'
require 'csv'

class OptPrs
	def self.parse(args)
		# The options specified on the command
		# line will be collected in *options*.
		# We set default values here.
		options = OpenStruct.new
		options.verbose = false
		options.dry = false
		options.noprompt = false
		options.keywords = []
		options.nokeywords = []
		options.opath = ""
		options.debug = false
		options.sort = false

		dfiles = []
		foundFlag = false
		args.each do |arg|
			if arg[0] == "-"
				foundFlag = true
			elsif not foundFlag
				dfiles += [arg]
				foundFlag = false
			else
				foundFlag = false
			end
		end
		options.dfiles = dfiles

		opt_parser = OptionParser.new do |opts|
			opts.banner = "Usage: mcollector.rb [OPTIONS] FILE0 FILE1 ..."

			opts.separator ""
			opts.separator "Optional:"

			opts.on("-k", "--keywords WORD0,WORD1,...", Array) do |keywords|
				options.keywords = keywords
			end

			opts.on("-i KEY0,KEY1,...", "--no-keywords WORD0,WORD1,... ", Array) do |nokeywords|
				options.nokeywords = nokeywords
			end

			opts.on("-o", "--output CSVFILE",
			        "CSV file to write the collected data",
			        "If no file is specified the program will",
			        "stream its output to stdout") do |p|
				options.opath = p
			end

			opts.on("-f", "Do not prompt. Be careful with this flag,",
			        "as it can result in files being overwritten.") do |noprompt|
				options.noprompt = noprompt
			end

			opts.on("-s", "--sort", "Sort CSV output") do |sortFlag|
				options.sort = sortFlag
			end

			opts.separator ""
			opts.separator "Common:"

			# No argument, shows at tail.  This will print an options summary.
			# Try it and see!
			opts.on_tail("-h", "--help", "Show this message") do
				puts opts
				exit
			end

			# Boolean switch
			opts.on_tail("-v", "--[no-]verbose", "Run verbosely") do |v|
				options.verbose = v
			end

			# Boolean switch
			opts.on_tail("--[no-]debug", "Debug mode; includes verbosity") do |d|
				options.debug = d
			end

		end
		opt_parser.set_summary_indent("  ")
		opt_parser.set_summary_width(34)
		opt_parser.parse!(args)
		options
	end  # parse()
end  # class OptPrs

$options = OptPrs.parse(ARGV)
# if debug be also verbose
$options.verbose = $options.verbose || $options.debug

def DEBUG(msg)
	puts msg if $options.debug
end

def VERBOSE(msg)
	puts msg if $options.verbose
end

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
$unitReg          = /[^\s]{1,#{$unitMaxSize}}/

# regex of assignment symbols
$linkReg = /=|-+>|=+>|:/ # divided by logical OR

# numerical value
$quantityReg = /(#{$numReg})#{$unitReg}?/

# quoted value
$quotationReg = /("[^"]+")/

# simple word value
$wordReg = /([^\s]+)/

# general value regex
$valReg = /#{$quotationReg}|#{$quantityReg}|#{$wordReg}/

# this function returns a regex which matches any
# <keyword> <space> <link> <space> <value>
# constellations. Moreover the <value> is captured,
# thus can be obtained by taking the first non nil
# capture object
def getKeyValueReg(keyword)
	/#{keyword}\s*#{$linkReg}\s*#{$valReg}/
end

##################
# GATHER RESULTS #
##################
class DataFileIterator
	# dfiles = array of data files,
	# e.g. ["pth/to/file0.md", "pth/to/file1.txt"]
	def initialize(options = {})
		options = {
			:dfiles => [],
		}.merge(options)
		@dfiles = options[:dfiles]
	end

	# this function can be used to iterate with a block structure over all
	# available file paths, e.g.
	# it = DataFileIterator.new(["./file1.txt", "../file2.txt"])
	# it.each_path do |filepath|
	#   puts filepath
	# end
	# will print all *full* paths to available data files, which are readable
	# ordinary files.
	def each_pth
		@dfiles.each do |fpth|
			pth = File.expand_path(fpth)
			if File.readable?(pth) && File.file?(pth)
				yield pth
			else
				STDERR.puts "WARNING: given file #{pth} is not readable" \
				            "or an ordinary file. And will be ignored"
			end
		end
	end

	# same as above but gives also the content of each file
	def each_content_with_pth
		each_pth do |fpth|
			f = File.open(fpth)
			content = f.read
			f.close
			yield content, fpth
		end
	end
end # DataFileIterator

# Takes a DataFileIterator iterates over the contents of the
# files and searches for the values assigned to the keywords.
# Returns: [[<csv first row>], [<csv second row>], ...]
# which is basically the CSV data without the headline.
def gather(df_it, keywords)
	if keywords.empty?
		STDERR.puts "I got no keywords to search for!"
		exit 1
	end

	# take a keyword and a string and search for the first
	# part, which matches the Regexp. From that match we
	# want to have the first capture, which is not nil
	grepValue = ->(key, str) {
		md = str.match(getKeyValueReg(key))
		return md.captures.select {|c| c != nil}[0] if md != nil
		return nil
	}

	res = []
	filesProcessed = 0

	df_it.each_content_with_pth do |c, pth|
		row = [] 
		keywords.each do |key|
			val = grepValue.call(key, c)
			row += ["N/A"] if val == nil
			row += [val]   unless val == nil
		end
		row += [pth] # per default each row ends with the data file path
		res += [row] # row must be enclosed to preserve the sublist structure
		filesProcessed += 1
	end

	VERBOSE("  - I processed #{filesProcessed} data files")
	res
end

# either output to stdout or write to file
def outputCSV(opath, csvRows, keywords, options = {})

	options = {
		:sort => false,
	}.merge(options)

	csvRows.sort! if options[:sort]

	# add the header
	csvStr = "#{keywords.join(',')},data-file-path\n"
	# we take the index, to prevent the sublists from being expanded
	DEBUG("  - CSV ROWS = #{csvRows}")
	csvRows.each_with_index do |row, i|
		DEBUG("  - ROW = #{row}")
		DEBUG("  - [*row].join(',') = #{[*row].join(',')}")
		csvStr << [*row].join(',') << "\n"
	end

	# WRITE TO STDOUT
	if opath.empty?
		puts csvStr
		return
	end

	# WRITE TO FILE
	f = File.open(opath, mode="w")
	f.write(csvStr)
	f.close
end


if __FILE__ == $0

	######################
	# CHECK INPUT VALUES #
	###################### 

	if $options.opath != "" # not equal to the default

		# CHECK IF OUTPUT DIRECTORY EXISTS
		opath = File.expand_path($options.opath)
		outdir = File.dirname(opath)
		if !File.directory?(outdir)
			STDERR.puts "ERROR: the directory #{outdir} does not exists! " \
			            "Create it first!"
			exit 1
		end

		# CHECK IF OUTPUT FILE ALREADY EXISTS
		if File.exists?(opath) && !$options.noprompt
			STDERR.puts  "CAUTION: the file #{opath} does already exists."
			STDERR.print "Do you want to replace it? [y/N]:"
			answer = gets.chomp
			if not %w[Yes Y y yes].include?(answer)
				puts "Going to exit..."
				exit 0
			end
		end
	end

	# CHECK IF KEYWORDS ARE GIVEN
	if $options.keywords.empty?
		STDERR.puts "ERROR: You did not give any keyword!"
		exit 1
	end

	# CHECK IF DATA FILES ARE AVAILABLE
	if $options.dfiles.empty?
		STDERR.puts "ERROR: You did not give any data file!"
		exit 1
	end

	####################
	# START PROCESSING #
	####################

	# GET THE DATA FILE ITERATOR
	df_it = DataFileIterator.new(:dfiles => $options.dfiles)

	# GREP ALL VALUES FROM FILE CONTENTS
	timestamp = Time.now
	csvRows = gather(df_it, $options.keywords)
	gatherT = Time.now - timestamp
	VERBOSE("  - processing the files took #{gatherT} seconds")

	# OUTPUT THE CSV DATA
	VERBOSE("  - sorting flag = #{$options.sort}")
	timestamp = Time.now
	outputCSV($options.opath, csvRows, $options.keywords, :sort => $options.sort)
	csvT = Time.now - timestamp
	VERBOSE("  - outputting the csv data took #{csvT} seconds")
end
