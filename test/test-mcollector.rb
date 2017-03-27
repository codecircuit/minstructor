#!/usr/bin/ruby

require 'test/unit'
require_relative '../mcollector'

# This test should check the functionality of the
# Command Line Interface by simulating a user interaction
# with the mcollector. To achieve that the test class
# generate some output files in a temporary directory
# with an exemplaric output.

class TestCLI < Test::Unit::TestCase

	@@tmpDirName = "test-results-168741616"
	@@tmpFileNames = []


	def setup
	# TODO use ruby class Dir
# Generate some random output
#echo ""
#echo "## Some random output"
#echo "  - exampleKey0 -> importantValue"
#printf "    anotherKey3  :  \t -00.654678  seconds\n"
#printf "\t important-key7   =   -86487  16674  whateverUnit\n"
#printf " --- finally-key99 \t ---> +0.6874e-08  the answer to everything is 42\n"
#echo "  smallkeyword  =    +7.68416e+684465 woow that is a large number"
#echo ""
	end

	# delete the temporary created files and directory
	def teardown
		# TODO use ruby class Dir
		@@tmpFileNames.each { |fname|
			File.delete(fname)
		}
	end

end

