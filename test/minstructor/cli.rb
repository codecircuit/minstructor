require 'test/unit'

require_relative '../../minstructor'

# This test should check the functionality of the
# Command Line Interface by simulating a user interaction
# with the minstructor. To achieve that the test class
# creates a dummy executable, which saves the
# command line parameters it has been executed with.
class TestCLI < Test::Unit::TestCase

	@@dummyScriptFile = "dummy-script.sh"
	@@defaultOutFilePrefix = "out_"

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
		%x(../minstructor.rb "./#{@@dummyScriptFile} [foo,bar] -k [3,4]" -f)
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
		%x(../minstructor.rb "./#{@@dummyScriptFile} -key0 a -imp=range(2) -blao linspace(0.4, 12, 3)" -f -n 3)
		f = File.open("dummy-script-executions.txt", "r")
		log = f.read()
		f.close()
		File.delete("dummy-script-executions.txt")
		lines = log.lines.map {|l| l.chomp} # remove \n
		assert_equal(3, lines.count("-key0 a -imp=1 -blao 0.4"))
	end

	def test_defaultOutputFileNaming
		%x(../minstructor.rb "./#{@@dummyScriptFile} -key0 [ a,  3] logspace(1,3,3)" -f -n 3 -o .)
		File.delete("dummy-script-executions.txt")
		for i in (0...18)
			outFileName = "./#{@@defaultOutFilePrefix}#{i}.txt"
			assert(File.exist? outFileName)
			File.delete(outFileName)
		end
	end

	def test_outputFilePrefix
		%x(../minstructor.rb "./#{@@dummyScriptFile} -key0 range(2)range(2)" -f -n 3 -o ./myoutputprefix)
		File.delete("dummy-script-executions.txt")
		for i in (0...12)
			outFileName = "./myoutputprefix_#{i}.txt"
			assert(File.exist? outFileName)
			File.delete(outFileName)
		end
	end

	def test_outputFileNumeration
		%x(../minstructor.rb "./#{@@dummyScriptFile} -key0 range(2)range(2)" -f -n 3 -o .)
		%x(../minstructor.rb "./#{@@dummyScriptFile} -key0 range(2)range(2)" -f -n 3 -o .)
		File.delete("dummy-script-executions.txt")
		for i in (0...24)
			outFileName = "./#{@@defaultOutFilePrefix}#{i}.txt"
			assert(File.exist? outFileName)
			File.delete(outFileName)
		end
	end

	# delete the temporary created executable
	def teardown
		File.delete(@@dummyScriptFile)
	end

end
