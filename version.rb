# minstructor mcollector version
$VERSION = "2.1"

# ruby version
$REQUIRED_RUBY_VERSION = "2.5.1"

def append_zeros_until_equal_length(a, b)
	diff = (a.length - b.length).abs
	return if diff == 0
	smaller_arr = a.length < b.length ? a : b
	smaller_arr.concat([0] * diff)
end

def version_is_older(curr_version, required_version)
	rv = required_version.split('.').map { |s| s.to_i }
	cv = curr_version.split('.').map { |s| s.to_i }
	append_zeros_until_equal_length(rv, cv)
	rv.zip(cv).each do |ri, ci|
		return true if ci < ri
		return false if ci > ri
	end
	return false
end

if version_is_older(RUBY_VERSION, $REQUIRED_RUBY_VERSION) then
	puts "Ruby version too old!"
	puts "Required: #{$REQUIRED_RUBY_VERSION}"
	puts "Current: #{RUBY_VERSION}"
	exit
end
