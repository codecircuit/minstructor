require 'csv'
require_relative './base.rb'
require_relative '../regular-expressions.rb'

# due to namespace conflicts we put this here
def parse_csv(csvstr)
	return CSV.parse(csvstr)
end

module MCollectorModule

	class CSV < Base

		def default_args
			return DefaultArgs.new({
				:separator => [",", "Separator for CSV format"],
				:prune => [true, "Remove extracted information for next module"],
			})
		end

		def apply(input_str, opt_args)

			opt_args = default_args.merge(opt_args)

			csvrow2hash = ->(row, col_names) {
				row_hash = {}
				row.zip(col_names).each do |val, colname|
					if !val.nil? and !colname.nil?
						row_hash[colname] = val
					end
				end
				return row_hash
			}

			md = $csvReg.match(input_str)
			# We only support one csv pattern per file up to now
			csvdata = parse_csv(md[0])
			col_names = csvdata.delete_at(0)
			rows = []
			csvdata.each do |row|
				rows.append(csvrow2hash.call(row, col_names))
			end
			pruned_str = input_str.clone
			pruned_str = md.pre_match + md.post_match # remove match from str

			return [rows, opt_args[:prune] ? pruned_str : input_str]
		end

		def name()
			return "csv"
		end

		def hname()
			return "CSV (column separated values)"
		end

		def help()
			intro_msg = "Search for CSV patterns in the output:

...
foo,bar,baz
1,2,3
4,5,6
...

One CSV pattern per input string is extracted

"
			example_msg = '{ :separator => ";", :prune => false }'
			return HelpMessage.new(default_args, intro_msg , example_msg, "")
		end
	end

end
