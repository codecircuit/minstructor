#!/usr/bin/ruby

require 'test/unit'
require_relative '../minstructor'

class TestRangeFunctions < Test::Unit::TestCase

	def test_range
		assert_equal([0,1,2], range(3))
		assert_equal([3,4,5], range(3,6))
		assert_equal([3,1003,2003], range(3,2004,1000))
		assert_raise(RangeError) {range(0, -1)}
		assert_raise(RangeError) {range(0, 0)}
	end

	def test_linspace
		assert_equal([0,-0.25,-0.5,-0.75,-1], linspace(0,-1,5))
		assert_equal([6,6.25,6.5,6.75,7], linspace(6,7,5))
		assert_equal([1,1,1,1,1], linspace(1,1,5))
		assert_raise(RangeError) {linspace(3,4,0)}
		assert_raise(RangeError) {linspace(3,4,-3)}
	end

	def test_logspace
		assert_equal([2,4,8], logspace(1,3,3,2))
		assert_equal([10,100,1000], logspace(1,3,3))
		assert_equal([1000,10], logspace(3,1,2))
		assert_equal([8,0.5], logspace(3,-1,2,2))
		assert_equal([16,25.3984,40.3175,64], logspace(4,6,4,2,4))
		assert_raise(RangeError) {logspace(1,3,0)}
		assert_raise(RangeError) {logspace(1,3,-1)}
	end

end

# This test should check the functionality of the
# Command Line Interface by simulating a user interaction
# with the minstructor. To achieve that the test class
# creates a dummy executable, which saves the
# command line parameters it has been executed with.
class TestCLI < Test::Unit::TestCase

	@@dummyScriptFile = "dummy-script.sh"

	def setup # create the dummy executable
		dummyScriptContent = <<-eos
		#!/bin/bash
# This script simply takes it input parameters and
# generates some random output with them. It should
# resemble the output of an example application.
# Moreover it saves the command line parameters with
# which it have been called in a file
# ./dummy-script-executions.txt

echo "$@" >> dummy-script-executions.txt

# Now we wan to detect the flags and the values the script
# has been called with. We say that a flag is a command line
# parameter with at least one '-' sign in the front, but
# without subsequent numbers, thus '-9foo' will not be detected
# as a command line argument, but as a value, whereas '-foo',
# will be detected as a command line flag.

args=($@)
types=()
while [[ -n "$1" ]]; do
	currArg="$1"
	if [[ -n `echo "$currArg" | grep -E "^-"` ]]; then
		if [[ ${#currArg} -gt 1 ]]; then
			if [[ -z `echo "${currArg[2]}" | grep -E "[0-9]"` ]]; then
				types=(${types[@]} "flag")
			else
				types=(${types[@]} "value")
			fi
		fi
	else
		types=(${types[@]} "value")
	fi
	shift
done

# We generate some exemplaric output
echo "# DUMMY SCRIPT EXECUTION OUTPUT"
echo "TODO enter lorem ipsum text here"
echo ""
echo "## Command line parameters"
echo "Now we iterate over the given parameters"
echo "number of Args = ${#args[@]}"
echo ""
for i in `seq 0 $((${#args[@]} - 1))`; do
	if [[ "${types[$i]}" == "flag" ]]; then
		argCropped=$(echo "${args[$i]}" | sed 's/^-\+//g')
		echo "  - cmd arg nr $i: cmd-arg-$argCropped = ${args[$(($i+1))]}"
	fi
done

# Generate some random output
echo ""
echo "## Some random output"
echo "  - exampleKey0 -> importantValue"
printf "    anotherKey3  :  \t -00.654678  seconds\n"
printf "\t important-key7   =   -86487  16674  whateverUnit\n"
printf " --- finally-key99 \t ---> +0.6874e-08  the answer to everything is 42\n"
echo "  smallkeyword  =    +7.68416e+684465 woow that is a large number"
echo ""
		eos
		f = File.open(@@dummyScriptFile, "w")
		f.write(dummyScriptContent)
		f.close
		File.chmod(0755,@@dummyScriptFile)
	end

	# This function takes a list of words and the lines
	# of a string and searches if there is a line containing
	# all given words
	#   - words = [word0, word1, word2, ... ]
	#   - lines = [line0, line1, line2, ... ]
	#   - returns = true, false
	def lineWithWordsExists(words, lines)
		return false if lines.empty?
		return true if words.empty?
		lines.select! { |line| 
			line.include?(words[0])
		}
		return lineWithWordsExists(words[1..-1], lines)
	end

	def test_twoLists
		%x(../minstructor.rb -c "./#{@@dummyScriptFile} [foo,bar] -k [3,4]" -f)
		f = File.open("dummy-script-executions.txt", "r")
		log = f.read()
		f.close()
		File.delete("dummy-script-executions.txt")

		# First we check if the script has been executed with the
		# wanted parameters. The order in which the command line
		# arguments are listed should be fixed by the user
		lines = log.lines.map {|l| l.chomp} # remove \n
		assert(lines.include?("foo -k 4"))
		assert(lines.include?("foo -k 3"))
		assert(lines.include?("bar -k 3"))
		assert(lines.include?("bar -k 4"))
		assert_equal(lines.length, 4)
	end

	def test_multipleExecutions
		%x(../minstructor.rb -c "./#{@@dummyScriptFile} -key0 a -imp=range(2) -blao linspace(0.4, 12, 3)" -f -n 3)
		f = File.open("dummy-script-executions.txt", "r")
		log = f.read()
		f.close()
		File.delete("dummy-script-executions.txt")
		lines = log.lines.map {|l| l.chomp} # remove \n
		assert_equal(3, lines.count("-key0 a -imp=1 -blao 0.4"))
	end

	# delete the temporary created executable
	def teardown
		File.delete(@@dummyScriptFile)
	end

end

