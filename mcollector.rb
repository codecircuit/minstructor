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

# You must remove white spaces before using this dictionary
floatingPointRegex = /[-+]?[[:digit:]]*\.?[[:digit:]]*/
integerRegex       = /[-+]?[[:digit:]]+/

unitMaxSize        = 10 # maximum size of a unit, e.g. `Byte` has 4
unitRegex          = /.{0,#{unitMaxSize}}/
keywordRegex       = /[-_a-zA-Z0-9]+/

$regexOfSymbols = [/=/, /-+>/, /=+>/]

$regexOfAssignmentExpr = {
	# EXAMPLE: Time_01  = 3.1654 s
	:equal => /\s*=\s*#{floatingPointRegex}\s?#{unitRegex}/,
	# EXAMPLE: Time_01 3.1654 s
	:space => /\s*#{floatingPointRegex}\s?#{unitRegex}/,
}

##################
# GATHER RESULTS #
##################

# Returns a ruby hash (dictionary) which contains the scratched data
def gather(dpath, keywords)
	return nil if dpath == "" or keywords.empty?

	## INITIALIZE RETURN DICTIONARY ##
	res = Hash.new
	keywords.each { |k| res[k] = [] }
	
	# find all files which should be read
	# up to now we read all files within one directory
	# system's find command should expand ~ automatically
	if $options.verbose
		puts "  - I got the keywords:"
		keywords.map { |k| puts "    '#{k}'"}
	end
	puts "  - my data directory #{dpath}" if $options.debug
	files = %x(find #{dpath} -type f -name "*.txt").split
	puts "FILES = #{files}"
	files = [files[0]] if $options.debug

	if $options.verbose
		puts "  - Searching for data in #{files.length} files"
	end

	if $options.verbose
		linesShowMax = 15
		if files.length < linesShowMax
			puts "  - I will search for keywords in the files:"
			files.each { |filename| puts "    #{filename}" }
		else
			puts "  - Here is an random extract of the file names:"
			files.sample(linesShowMax).each { |filename| puts "    #{filename}" }
		end
	end
	if files.empty?
		puts "WARNING: I could not gather results, because I could not find"
		puts "any file with the search string '#{dpath}'"
		return nil
	end

	getLineWithKey = ->(str, key) {
		keyInd = str.index(key)
		return "N/A" if keyInd == nil
		# get the line with the keyword
		delme = str[keyInd..-1]
		line = str[keyInd..-1].lines.to_a()[0]
		return line
	}

	# if files were found just proceed reading them
	files.each do |filename|
		file = File.open(filename)
		content = file.read
		if $options.debug
			puts "THE FILE HAS THE CONTENT:"
			puts "#{content}"
			puts "CONTENT END"
		end
		file.close
		keywords.each do |keyword|
			line = getLineWithKey.call(content, keyword)
			puts "I found the line with keyword: #{line}" if $options.debug
			if line == "N/A"
				res[keyword].push(line) 
				next
			end
			line.gsub!(keyword,'') # remove the keyword
			$regexOfSymbols.each { |reg| line.gsub!(reg,'') } # delete symbols
			words = line.split()
			value = "N/A"    if words.empty?
			res[keyword].push(words[0]) if not words.empty?
		end
	end

	return res
end

# converts dictionary with vectors to a string
# representing the data in a CSV format
def dictToString(dict)

	res = ""

	if dict.empty?
		puts "WARNING: no key value pairs found. The output will be empty"
		return ""
	end

	# write the CSV header first
	csvString = CSV.generate do |csv|
		csv << dict.keys
	end

	# get the number of rows; here we assume that every vector belonging to a
	# key has the same length
	numRows = dict[dict.keys[0]].length

	for r in 0..numRows-1
		row = []
		dict.each do |key,val|
			row.push(dict[key][r])
		end
		csvString += CSV.generate { |csv| csv << row }
	end

	return csvString
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
	csvDict = gather($options.dpath, $options.keywords)
	gatherT = Time.now - timestamp
	puts "  - processing the files took #{gatherT} seconds" if $options.verbose

	timestamp = Time.now
	csvStr = dictToString(csvDict)
	outputCSV($options.opath, csvStr)
	csvT = Time.now - timestamp
	puts "  - writing the csv file took #{csvT} seconds" if $options.verbose
end
