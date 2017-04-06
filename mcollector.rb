#!/usr/bin/ruby

## Measurement Collector
#
# If you have several output files of a program run and you want
# to collect the data of all files into one .csv file, this is
# the appropriate program for you.

require 'optparse'
require 'ostruct'
require 'pp'
require 'csv'

class OptparseExample

	def self.parse(args)
		# The options specified on the command line will be collected in *options*.
		# We set default values here.
		options = OpenStruct.new
		options.verbose = false
		options.dry = false
		options.dpath = "."
		options.noprompt = false
		options.keywords = []
		options.opath = ""
		options.debug = false

		opt_parser = OptionParser.new do |opts|
			opts.banner = "Usage: mcollector.rb [options]"

			opts.separator ""
			opts.separator "Mandatory:"

			opts.on("-k", "--keywords <key0,key1,...>", Array) do |keywords|
				options.keywords = keywords
			end

			opts.separator ""
			opts.separator "Optional:"

			opts.on("-d", "--data-dir <pth/to/data/dir>",
			        "DEFAULT = current directory",
			        "All .txt files in this directory will be processed.") do |p|
				options.dpath = p
			end

			opts.on("-o", "--output <pth/to/output/file.csv>",
			        ".csv file to write the collected data",
			        "If no file is specified the program will stream",
			        "its output to stdout") do |p|
				options.opath = p
			end

			opts.on("-f", "Do not prompt. Be careful with this flag,",
			        "as it can result in files being overwritten.") do |noprompt|
				options.noprompt = noprompt
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

		opt_parser.parse!(args)
		options
	end  # parse()

end  # class OptparseExample

$options = OptparseExample.parse(ARGV)
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

$expReg = /[eE][-+][[:digit:]]+/
$numReg = /[-+]?[[:digit:]]+(?:\.[[:digit:]]+)?#{$expReg}?/
#wordRegex          = /[[:word:]]+/ # REMOVE ME
#stringRegex        = /".+"/ # REMOVE ME

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

# general value regex
$valReg = /#{$quotationReg}|#{$quantityReg}/

# this function returns a regex which matches any
# <keyword> <space> <link> <space> <value>
# constellations. Moreover the <value> is captured,
# thus can be obtained by taking the first non nil
# capture object
def getKeyValueReg(keyword)
	return /#{keyword}\s*#{$linkReg}\s*#{$valReg}/
end

##################
# GATHER RESULTS #
##################
class DataFileIterator
	# dpath = data path which must be a directory
	# ext = allowd extension for data files in the given directory, e.g. ".txt"
	def initialize(dpath, ext)
		dpath = File.expand_path(dpath)
		if not File.directory?(dpath)
			puts "ERROR: the given data directory does not exists!"
			exit 1
		end
		@d = Dir.new(dpath)
		@ext = ext
	end

	# this function can be used to iterate with a block structure over all
	# available file paths, e.g.
	# it = DataFileIterator.new(dpath, ".txt")
	# it.each_path do |filepath|
	#   puts filepath
	# end
	# will print all paths to available data files, which have the wanted
	# extension and are readable.
	def each_pth
		@d.each do |fname|
			pth = @d.path + "/" + fname
			currExt = pth[(-1)*@ext.length()..-1]
			if File.readable?(pth) and File.file?(pth) and  currExt == @ext
				yield pth
			end
		end
	end

	# same as above but gives also the content of each file
	def each_content_with_pth
		each_pth do |fpth|
			f = File.open(fpth)
			content = f.read()
			f.close()
			yield content, fpth
		end
	end

end

# Takes a DataFileIterator iterates over the contents of the
# files and searches for the values assigned to the keywords
#
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
		return md.captures.select {|c| c != nil}[0]
	}


	res = []
	filesProcessed = 0

	df_it.each_content_with_pth do |c, pth|
		row = [pth] # per default each row starts with the data file path
		keywords.each do |key|
			val = grepValue(key, c)
			row += ["N/A"] if val == nil
			row += [val]   unless val == nil
		end
		res += row
		filesProcessed += 1
	end

	VERBOSE("  - I processed #{filesProcessed} data files")
	return res
end

# either output to stdout or write to file
def outputCSV(opath, csvStr)

	# WRITE TO STDOUT
	if opath.empty?
		puts csvStr
		return
	end

	# WRITE TO FILE
	## CHECK IF FILE ALREADY EXISTS ##
	if File.exists?(opath) and not $options.noprompt
		puts "CAUTION: the file #{opath} does already exists."
		print "Do you want to replace it? [y/N]:"
		answer = gets.chomp
		if not %w[Yes Y y yes].include?(answer)
			puts "Going to exit..."
			exit
		end
	end

	## CHECK IF DIRECTORY EXISTS ##
	abs_opath = File.absolute_path(opath)
	abs_dir = File.dirname(abs_opath)
	if not File.directory?(abs_dir)
		puts "ERROR: the directory #{abs_dir} does not exists! Create it first!"
		exit
	end

	## WRITE ##
	f = File.open(abs_opath, mode="w")
	f.write(csvStr)
	f.close()
end

if __FILE__ == $0
	timestamp = Time.now
	dataFiles = getDataFiles($options.dpath)
	if dataFiles.empty?
		puts "I could not find any .txt files!"
		exit 1
	end
	if $options.keywords.empty?
		puts "I don't have any keywords to search for!"
		exit 1
	end
	csvDict = gather(dataFiles, $options.keywords)
	gatherT = Time.now - timestamp
	puts "  - processing the files took #{gatherT} seconds" if $options.verbose

	timestamp = Time.now
	csvStr = dictToString(csvDict)
	outputCSV($options.opath, csvStr)
	csvT = Time.now - timestamp
	puts "  - writing the csv file took #{csvT} seconds" if $options.verbose
end
