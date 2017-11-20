#!/usr/bin/env ruby

require 'optparse'
require 'ostruct'
require 'csv'
require 'set'

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
		options.nokeywords = Set.new
		options.wkeywords = false
		options.opath = ""
		options.debug = false
		options.sort = false

		opt_parser = OptionParser.new do |opts|
			opts.banner = "Usage: mcollector.rb [OPTIONS] FILE0 FILE1 ..."

			opts.separator ""
			opts.separator "Options:"

			opts.on("-k", "--keywords WORD0,WORD1,... ",
			        "Keywords to search for;",
			        "Disables automatic keyword detection", Array) do |keywords|
				options.keywords = keywords
			end

			opts.on("-i", "--ignore-keywords WORD0,WORD1,... ",
			        "Ignore this keywords", Array) do |nokeywords|
				options.nokeywords = Set.new(nokeywords)
			end

			opts.on("-w", "--weird-keywords",
			        "Allow automatic detected keywords",
					"to contain all characters except comma") do |wkeywords|
				options.wkeywords = wkeywords
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
			opts.on_tail("-v", "--verbose", "Run verbosely") do |v|
				options.verbose = v
			end

			# Boolean switch
			opts.on_tail("--debug", "Debug mode; includes verbosity") do |d|
				options.debug = d
			end

		end
		opt_parser.set_summary_indent("  ")
		opt_parser.set_summary_width(25)
		opt_parser.parse!(args)
		options
	end  # parse()
end  # class OptPrs

$options = OptPrs.parse(ARGV)
$options.dfiles = Array.new(ARGV) # get mandatory args

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

# Takes a DataFileIterator to iterate over the contents of the
# files and searches for the values assigned to the keywords.
# Options: - keywords = [WORD0, WORD1, ...] search for given keywords only
#          - nokeywords = [WORD0, WORD1, ...] ignore these keywords
# Returns: ALLKEYWORDS, [{ KEYWORD0 => A, KEYWORD1 => Z, ... }, ...]
# I choose that result format, because not every file contains
# every keyword. When actually writing the CSV file, the data format
# is beneficial in the sense of memory access.
def gather(df_it, options = {})
	DEBUG("[+] gather()")

	options = {
		:keywords => [],
		:nokeywords => [],
	}.merge(options)

	DEBUG("  - keywords = #{options[:keywords]}")
	DEBUG("  - nokeywords = #{options[:nokeywords].to_a}")

	# nokeywords take precedence over keywords
	options[:keywords] -= options[:nokeywords].to_a

	# take a keyword and a string and search for the first
	# part, which matches the Regexp. From that match we
	# want to have the first capture, which is not nil
	grepValue = ->(key, str) {
		md = str.match(getKeyValueReg(key))
		return md["value"] if md != nil
		return nil
	}

	res = []
	allkeywords = Set.new(options[:keywords])
	filesProcessed = 0

	# User gave keywords on the command line
	if !options[:keywords].empty?
		DEBUG("  - User gave keywords = #{options[:keywords]}")
		df_it.each_content_with_pth do |c, pth|
			row = {}
			options[:keywords].each do |key|
				DEBUG("    - now searching for key: #{key}")
				val = grepValue.call(key, c)
				DEBUG("    - grepValue = #{val}")
				row[key] = val unless val == nil
			end
			# per default each row ends with the data file path
			row["data-file-path"] = pth
			res.push(row)
			filesProcessed += 1
		end

	# User gave no keywords on the command line
	else
		df_it.each_content_with_pth do |c, pth|
			md = c.match(getKeyValueReg) # function call (see above)
			row = {}
			# Now we search iteratively for matching key value expressions.
			# In each step we delete the string part with and before the match.
			while md != nil
				val = md["value"]
				key = md["keyword"]
				if !options[:nokeywords].include?(key) # ignore some keys
					allkeywords.add(key)
					row[key] = val
				end
				c = md.post_match # remove match and part before match
				md = c.match(getKeyValueReg) # function call (see above)
			end
			# per default each row ends with the data file path
			row["data-file-path"] = pth
			filesProcessed += 1
			res.push(row)
		end
	end

	allkeywords.add("data-file-path")

	VERBOSE("  - I processed #{filesProcessed} data files")
	return allkeywords, res
	DEBUG("[-] gather()")
end

# either output to stdout or write to file
#  - opath = path to CSV file
#  - csvRowHashes = array of hashes containing the data of each row
#  - allkeywords = set of all keywords in csvRowHashes
def outputCSV(opath, csvRowHashes, allkeywords, options = {})
	DEBUG("[+] outputCSV()")
	DEBUG("  - csvRowHashes = #{csvRowHashes}")

	options = {
		:sort => false,
	}.merge(options)

	# first we convert to simple csvRows
	csvRows = []
	DEBUG("  - converting to simple arrays")
	csvRowHashes.each do |rowHash|
		rowHash.default = "N/A"
		currRow = []
		allkeywords.each do |key|
			currRow.push(rowHash[key])
		end
		csvRows.push(currRow)
	end

	csvRows.sort! if options[:sort]

	# add the header and ensure that the keywords have no
	# preceeding and trailing whitespace characters
	csvStr = "#{allkeywords.map { |k| k.strip }.to_a.join(',')}\n"

	DEBUG("  - CSV ROWS = #{csvRows}")
	csvRows.each_with_index do |row, i|
		DEBUG("  - ROW = #{row}")
		DEBUG("  - [*row].join(',') = #{[*row].join(',')}")
		csvStr << [*row].join(',') << "\n"
	end

	# WRITE TO STDOUT
	if opath.empty?
		puts csvStr
		DEBUG("[-] outputCSV()")
		return
	end

	# WRITE TO FILE
	f = File.open(opath, mode="w")
	f.write(csvStr)
	f.close
	DEBUG("[-] outputCSV()")
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
			# We must clear ARGV here, because if there are file paths
			# in ARGV the content of the files seems to be read and
			# subsequently processed by the `gets` function, which
			# results in non-user answers to the question.
			ARGV.clear
			answer = gets.chomp
			if not %w[Yes Y y yes].include?(answer)
				puts "Going to exit..."
				exit 0
			end
		end
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
	DEBUG("  - nokeywords = #{$options.nokeywords}")
	timestamp = Time.now
	allkeywords, csvRowHashes = gather(df_it,
	                              :keywords => $options.keywords,
	                              :nokeywords => $options.nokeywords)
	gatherT = Time.now - timestamp
	VERBOSE("  - processing the files took #{gatherT} seconds")

	# OUTPUT THE CSV DATA
	VERBOSE("  - sorting flag = #{$options.sort}")
	timestamp = Time.now
	outputCSV($options.opath, csvRowHashes, allkeywords, :sort => $options.sort)
	csvT = Time.now - timestamp
	VERBOSE("  - outputting the csv data took #{csvT} seconds")
end
