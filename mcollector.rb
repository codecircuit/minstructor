#!/usr/bin/env ruby

require 'optparse'
require 'ostruct'
require 'csv'
require 'set'

require_relative './mcollector-modules/available-modules.rb'
require_relative './math.rb'
require_relative './version.rb'

$lost_file = ""

def parse_hash(str)
	if File.exist?(str)
		# we accidentally got a file here
		$lost_file = str
		return {}
	end
	begin
		h = eval(str)
	rescue
		raise ArgumentError, "Cannot evaluate additional module arguments.
		                      Please give valid Ruby syntax!"
	end
	if h.class != Hash
		raise ArgumentError, "Cannot evaluate additional module arguments.
		                      Please give a Ruby Hash object!"
	end
	return h
end

class OptPrs
	def self.parse(args)
		# The options specified on the command
		# line will be collected in *options*.
		# We set default values here.
		options = OpenStruct.new
		options.verbose = false
		options.dry = false
		options.noprompt = false
		options.opath = ""
		options.debug = false
		options.sort = false
		options.recursive = false
		options.separator = ','
		options.active_module_names = ["akav"]
		options.active_modules_optargs = {}
		options.sql = false
		options.sql_user = ""
		options.sql_host = "localhost"
		options.sql_password = ""
		options.sql_table = ""
		options.sql_database = "mcollector"

		opt_parser = OptionParser.new do |opts|
			opts.banner = "Usage: mcollector.rb [OPTIONS] FILE0 FILE1 ..."

			opts.separator ""
			opts.separator "Modules:"

			# Use this flag to overwrite defaults of `active_module_names`
			module_flag_found = false
			$available_modules.each do |m|
				opts.on("--module-enable-" + m.name() + " [ARGS_AS_RUBYHASH]",
						"Enable module " + m.name()) do |mf|
					mf = mf || "{}"
					mf = parse_hash(mf)
					options.active_modules_optargs[m.name()] = mf
					if mf
						if !module_flag_found
							options.active_module_names = [m.name()]
							module_flag_found = true
						else
							options.active_module_names.append(m.name())
						end
					end
				end
			end

			$available_modules.each do |m|
				opts.on("--module-help-" + m.name(),
						"Show help message of module " + m.hname()) do |mf|
					puts ""
					puts "# Module: " + m.hname()
					puts m.help()
					exit
				end
			end

			opts.separator ""
			opts.separator "Options:"

			opts.on("-o", "--output CSVFILE",
			        "CSV file to write the collected data",
			        "If no file is specified the program will",
			        "stream its output to stdout") do |p|
				options.opath = p
			end

			opts.on("--sql-database NAME", "SQL database") do |name|
				options.sql = true
				options.sql_database = name
			end

			opts.on("--sql-table NAME", "SQL table for data insertion") do |name|
				options.sql = true
				options.sql_table = name
			end

			opts.on("--sql-user NAME",
					"SQL username") do |name|
				options.sql = true
				options.sql_user = name
			end

			opts.on("--sql-host HOST",
					"SQL host, e.g. `localhost`, `192.168.5.62`,",
					"or `mydatabase.com`") do |host|
				options.sql = true
				options.sql_host = host
			end

			opts.on("--sql-password PASSWORD",
					"SQL password") do |pass|
				options.sql = true
				options.sql_password = pass
			end

			opts.on("--separator CHARACTER",
			        "If another separator than ',' is desired",
			        "for the tabular output") do |s|
				options.separator = s
			end

			opts.on("-r", "--recursive",
			        "If a directory is given as an input, search",
			        "recursively in that directory for data files") do |r|
				options.recursive = r
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

			opts.on_tail("--version", "show version") do |v|
				puts $VERSION
				exit
			end

		end
		opt_parser.set_summary_indent("  ")
		opt_parser.set_summary_width(25)
		opt_parser.parse!(args)
		options
	end  # parse()
end  # class OptPrs

def append_if_not_empty(arr, val)
	if val.empty?
		return arr
	else
		return arr.append(val)
	end
end

$options = OptPrs.parse(ARGV)
# get mandatory args
$options.dfiles = append_if_not_empty(Array.new(ARGV), $lost_file)

# if debug be also verbose
$options.verbose = $options.verbose || $options.debug

def DEBUG(msg)
	puts msg if $options.debug
end

def VERBOSE(msg)
	puts msg if $options.verbose
end

##################
# GATHER RESULTS #
##################

def directoryEntries(dir, recursive = false)
	DEBUG("[+] directoryEntries(#{dir}):")
	result = []
	next_dirs = []
	Dir.entries(dir).each do |entry|
		DEBUG("  - found entry #{entry}")
		next if entry == ".." or entry == "."
		pth = dir + '/' + entry
		if File.file?(pth)
			DEBUG("    - is a file")
			result += [pth]
		elsif Dir.exist?(pth)
			next_dirs += [pth]
		end
	end
	if recursive
		next_dirs.each do |d|
			result += directoryEntries(d, true)
		end
	end
	DEBUG("[-] directoryEntries()")
	return result
end

class DataFileIterator
	# dfiles = array of data files or directories,
	# e.g. ["pth/to/file0.md", "pth/to/file1.txt", "pth/take_this_dir"]
	# in case of a directory all the files within that directory are taken
	def initialize(options = {})
		DEBUG("[+] DataFileIterator():")
		options = {
			:dfiles => [],
		}.merge(options)
		@dfiles = []
		@num_files_processed = 0
		options[:dfiles].each do |pth|
			DEBUG("  - checking pth #{pth}")
			if Dir.exist?(pth)
				DEBUG("  - Adding files of directory #{pth} = #{directoryEntries(pth, $options.recursive)}")
				@dfiles += directoryEntries(pth, $options.recursive)
			else
				@dfiles += [pth]
			end
		end
		DEBUG("[-] DataFileIterator()")
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
				@num_files_processed += 1
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
			@num_files_processed += 1
			yield content, fpth
		end
	end

	def num_files_processed
		return @num_files_processed
	end
end # DataFileIterator

def maybe_at(arr, i)
	return nil if !i
	return arr[i]
end

##
# `output[i] = f(keys[i], values[j]) ? values[j] : check other values`
# Preserves the order of `keys`. Example:
#
# ```
# keys = ["foo", "bar", "baz", "waldo"]
# values = [qux, quux, quuz, grault, garply]
# f = ->(str, obj) {
#   return str == obj.name()
# }
# found_values = find_select_with(keys, values, f)
# ```
# So if `found_values = [qux, quuz, nil, grault]` then
# `qux.name() = "foo", quuz.name() = "bar", grault.name() = "waldo"`. If
# on object is taken into the result list, it is removed from the
# values list internally. Thus no object can be listed twice.

def find_select_with(keys, values, f)
	found = []
	keys.each do |k|
		i = values.index { |v| f.call(k, v) }
		# i can be nil
		found.append(maybe_at(values, i))
	end
	return found
end

##
# Merge all hashes to one hash

def merge_all(harray)
	if harray.class != Array
		raise ArgumentError, "Give an array with hashes to merge_all! Instead you give #{harray}"
	end
	return {} if harray.empty?
	h = harray.pop
	DEBUG("Calling merge_all recursively with harray #{harray}")
	return h.merge(merge_all(harray))
end

##
# Denotes the list of lists of hashes for this file. Later we calc the
# cartesian product of all hashes. Example:
# ```
# [
# # hashes from module A
#   [
#     {"foo" => "7", "bar" => "8"},
#     {"foo" => "9", "bar" => "10"}
#   ],
# # hashes from module B
#   [
#     {"qux" => "wobble", "quuz" => "flob" },
#     {"qux" => "xyzzy", "quuz" => "boop" },
#     {"qux" => "corge", "quuz" => "plugh" }
#   ]
# ]
# ```
#
# The resulting lines in the CSV file from this data file is:
#
# ```
# [
#   {"foo" => "7", "bar" => "8", "qux" => "wobble", "quuz" => "flob" },
#   {"foo" => "7", "bar" => "8", "qux" => "xyzzy", "quuz" => "boop" },
#   {"foo" => "7", "bar" => "8", "qux" => "corge", "quuz" => "plugh" },
#   {"foo" => "9", "bar" => "10", "qux" => "wobble", "quuz" => "flob" },
#   {"foo" => "9", "bar" => "10", "qux" => "xyzzy", "quuz" => "boop" },
#   {"foo" => "9", "bar" => "10", "qux" => "corge", "quuz" => "plugh" }
# ]
# ```

class ModuleHashes

	def initialize
		@module_hashes = []
	end

	def append(hashes)
		if hashes.class != Array
			raise ArgumentError, "You must append arrays to ModuleHashes"
		end
		hashes.each do |h|
			if h.class != Hash
				raise ArgumentError, "You must not append non-Hashes to ModuleHashes object"
			end
		end
		@module_hashes.append(hashes)
	end

	def get_data
		return @module_hashes
	end

	def combine_module_hashes
		DEBUG("combine_module_hashes[+]:")
		combs = combinations([@module_hashes])
		combs.map! { |hashlist| 
			DEBUG("combs = #{combs}, going to call merge_all with #{hashlist}")
			merge_all(hashlist)
		}
		return combs
	end

end

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

	row_hashes = []

	#### take the active modules from all available modules ####
	active_modules = $available_modules.select do |mod|
		$options.active_module_names.include?(mod.name)
	end

	name_eq = ->(name, mod) {
		return name == mod.name()
	}

	active_modules = find_select_with($options.active_module_names, $available_modules, name_eq)
	nil_index = active_modules.index { |m| m.nil? }
	if nil_index
		raise ArgumentError,"Required module with name `#{$options.active_module_names[nil_index]}` does not exist!"
	end
	if active_modules.empty?
		raise ArgumentError,"No active modules"
	end

	#### apply the modules ####
	# now we have the active modules in the correct order
	df_it.each_content_with_pth do |c, pth|
		all_module_hashes = ModuleHashes.new
		active_modules.each do |m|
			DEBUG("Apply module #{m.name}")
			optargs = $options.active_modules_optargs[m.name]
			optargs = {} if optargs.nil?
			if optargs.class != Hash
				raise ArgumentError, "Wrong format for optional module arguments! Please give a ruby Hash!"
			end
			hashes, c = m.apply(c, optargs)
			all_module_hashes.append(hashes)
		end
		all_module_hashes.append([{"data-file-path" => pth}])
		DEBUG("all_module_hashes.get_data = #{all_module_hashes.get_data}")
		DEBUG("all_module_hashes.combine modules hashes = #{all_module_hashes.combine_module_hashes}")
		row_hashes += all_module_hashes.combine_module_hashes
	end

	VERBOSE("  - mcollector processed #{df_it.num_files_processed} data files")
	DEBUG("[-] gather()")
	return row_hashes
end

def expandSeparator(s)
	s.gsub('\t', "\t")
end

def find_all_distinct_keys(array_of_hashes)
	cnames = Set.new
	array_of_hashes.each do |h|
		h.each_key do |k|
			cnames.add(k)
		end
	end
	return cnames
end

def rowHashes2CSVString(csvRowHashes, sort)
	column_names = find_all_distinct_keys(csvRowHashes)

	# first we convert to simple csvRows
	csvRows = []
	DEBUG("  - converting to simple arrays")
	csvRowHashes.each do |rowHash|
		rowHash.default = "N/A"
		currRow = []
		column_names.each do |key|
			currRow.push(rowHash[key])
		end
		csvRows.push(currRow)
	end

	csvRows.sort! if sort

	curr_separator = expandSeparator($options.separator)
	DEBUG("  - curr separator = #{curr_separator}")

	# add the header and ensure that the column names have no
	# preceeding and trailing whitespace characters
	csvStr = "#{column_names.map { |k| k.strip }.to_a.join(curr_separator)}\n"

	DEBUG("  - CSV ROWS = #{csvRows}")
	csvRows.each_with_index do |row, i|
		quoted_row = row.map do |e|
			if not e.include?(curr_separator) then
				e
			else
				"\"#{e}\""
			end
		end
		DEBUG("  - ROW = #{quoted_row}")
		DEBUG("  - [*quoted_row].join(#{curr_separator}) = #{[*quoted_row].join(curr_separator)}")
		csvStr << [*quoted_row].join(curr_separator) << "\n"
	end
	return csvStr
end

#  - opath = path to CSV file
#  - csvRowHashes = array of hashes containing the data of each row
def outputCSV(opath, csvRowHashes, options = {})
	DEBUG("[+] outputCSV()")
	DEBUG("  - csvRowHashes = #{csvRowHashes}")

	options = {
		:sort => false,
	}.merge(options)

	csvStr = rowHashes2CSVString(csvRowHashes, options[:sort])

	# WRITE TO FILE
	f = File.open(opath, mode="w")
	f.write(csvStr)
	f.close
	DEBUG("[-] outputCSV()")
end

# String > Float > Integer
def type_prior(ta, tb)
	if ta == String or tb == String
		return String
	end
	if ta == Float or tb == Float
		return Float
	end
	return Integer
end

def deduce_types_of_keys(csvRowHashes)
	types = {}
	csvRowHashes.each do |rowHash|
		rowHash.each do |k,v|
			begin
				Integer(v)
				curr_t = Integer
			rescue ArgumentError
				begin
					Float(v)
					curr_t = Float
				rescue ArgumentError
					curr_t = String
				end
			end

			types[k] = type_prior(curr_t, types[k])
		end
	end
	return types
end

def castHashValsToType(hash_with_vals, hash_with_types)
	cpy = {}
	hash_with_vals.each do |k,v|
		cpy[k] = v.to_i() if hash_with_types[k] == Integer
		cpy[k] = v.to_s() if hash_with_types[k] == String
		if hash_with_types[k] == Float
			f = v.to_f()
			if f == Float::INFINITY
				cpy[k] = nil
			else
				cpy[k] = f
			end
		end
	end
	return cpy
end

def enum_real_type_comp(et, rt)
	if et == :float and rt == Float
		return true
	end
	if et == :string and rt == String
		return true
	end
	if et == :integer and rt == Integer
		return true
	end
	return false
end

#  - csvRowHashes = array of hashes containing the data of each row
def outputSQL(user, host, password, table, database, csvRowHashes, options = {})
	DEBUG("[+] outputSQL()")
	DEBUG("  - csvRowHashes = #{csvRowHashes}")

	options = {
	# :possible_option => true, 
	}.merge(options)

	column_names = find_all_distinct_keys(csvRowHashes)
	# Only load the sequel gem when it is actually needed
	begin
		require 'sequel'
	rescue LoadError
		puts "ERROR: cannot load package `sequel`, which is required for SQL insertion (`$ gem install sequel`)"
		exit 1
	end

	begin
		db = Sequel.mysql2(:host => host, :username => user, :password => password, :database => database)
	rescue Sequel::AdapterNotFound
		puts "ERROR: cannot load package `mysql2`, which is required for SQL insertion (`$ gem install mysql2`)"
		exit 1
	end
	if $options.debug
		require 'logger'
		db.loggers << Logger.new($stdout)
	end
	col_types = deduce_types_of_keys(csvRowHashes)
	DEBUG("  - col_types = #{col_types}")
	if db.table_exists?(table)
		ex = {}
		db.schema(table).each do |e|
			ex[e[0]] = e[1]
		end
		DEBUG("  - check if sql table already exists = #{ex}")
		# Add not existing columns
		col_types.each do |colname, coltype|
			# Here we have the problem that we just save the colnames as strings
			# but the Sequel gem saves them as enumeration like `:"colname"`
			# which is equivalent to just `:colname`
			sequel_colname = colname.to_sym()
			if not ex.has_key?(sequel_colname)
				DEBUG("  - try to add colum #{colname}")
				db.add_column(table, colname, coltype)

			# If the column already exists it must have the same type
			elsif not enum_real_type_comp(ex[sequel_colname][:type], coltype)
				if not $options.noprompt
					STDERR.puts "CAUTION: The database table `#{table}` already exists and has a " \
						"column with name `#{colname}` and type `#{ex[sequel_colname][:type]}`, " \
						"but the type of the current dataset for column `#{colname}` is " \
						"`#{coltype}`. Should the old table be deleted? [y/N]:"
					ARGV.clear
					answer = gets.chomp
					if not %w[Yes Y y yes].include?(answer)
						puts "Going to exit..."
						exit 0
					end
				end
				db.create_table! table do
					col_types.each do |k, ktype|
						column(k, ktype)
					end
				end
				break
			end
			
		end
	else # table does not exist
		db.create_table table do
			col_types.each do |k, ktype|
				column(k, ktype)
			end
		end
	end

	items = db[table.to_sym()]
	csvRowHashes.each do |csvRowHash|
		typedRowHash = castHashValsToType(csvRowHash, col_types)
		items.insert(typedRowHash)
	end

	DEBUG("[-] outputSQL()")
end

def outputStdout(csvRowHashes, options = {})
	DEBUG("[+] outputStdout()")
	DEBUG("  - csvRowHashes = #{csvRowHashes}")

	options = {
		:sort => false,
	}.merge(options)

	csvStr = rowHashes2CSVString(csvRowHashes, options[:sort])

	puts csvStr
	DEBUG("[-] outputStdout()")
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
	timestamp = Time.now
	csvRowHashes = gather(df_it)
	gatherT = Time.now - timestamp
	VERBOSE("  - processing the files took #{gatherT} seconds")
	DEBUG("  - csvRowHashes = #{csvRowHashes}")

	# OUTPUT THE CSV DATA
	VERBOSE("  - sorting flag = #{$options.sort}")
	timestamp = Time.now
	if not $options.opath.empty?
		outputCSV($options.opath, csvRowHashes, :sort => $options.sort)
	end
	if $options.sql
		outputSQL($options.sql_user, $options.sql_host, $options.sql_password, $options.sql_table, $options.sql_database, csvRowHashes)
	end
	if $options.opath.empty? and not $options.sql
		outputStdout(csvRowHashes, :sort => $options.sort)
	end
	csvT = Time.now - timestamp
	VERBOSE("  - outputting the csv data took #{csvT} seconds")
end
