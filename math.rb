# takes a list [[a, [b, c], 0, [3, 4], d]]
# Be aware of the double wrapping list brackets
# and returns all possible combinations
#   - [a, b, 0, 3, d]
#   - [a, b, 0, 4, d]
#   - [a, c, 0, 3, d]
#   - [a, c, 0, 4, d]
#
# Inner lists can be empty
def combinations(l)

	# Just delete empty lists
	l.map { |e| e.delete([]) if e.class == Array }
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
