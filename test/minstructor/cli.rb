require 'test/unit'

require_relative '../../minstructor'

$thisDir = File.dirname(File.expand_path(__FILE__))
$minstructor = "#{$thisDir}/../../minstructor.rb"

# This test should check the functionality of the
# Command Line Interface by simulating a user interaction
# with the minstructor. To achieve that the test class
# creates a dummy executable, which saves the
# command line parameters it has been executed with.
class TestCLI < Test::Unit::TestCase

	@@dummyScriptFile = "#{$thisDir}/dummy-script.sh"
	@@dummyScriptLogFile = "#{$thisDir}/dummy-script-executions.txt"
	@@defaultOutFilePrefix = "out_"

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
		%x(#{$minstructor} "#{@@dummyScriptFile} [foo,bar] -k [3,4]" -f)
		f = File.open(@@dummyScriptLogFile, "r")
		log = f.read()
		f.close()
		File.delete(@@dummyScriptLogFile)

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

	def test_twoListsWithSlurm
		stdout = %x(#{$minstructor} --dry-run -b slurm "#{@@dummyScriptFile} [foo,bar] -k [3,4]" -f)

		# First we check if the script has been executed with the
		# wanted parameters. The order in which the command line
		# arguments are listed should be fixed by the user
		lines = stdout.lines.map {|l| l.chomp} # remove \n
		assert(lines.any?{ |l| l.include?("foo -k 4") } )
		assert(lines.any?{ |l| l.include?("foo -k 3") } )
		assert(lines.any?{ |l| l.include?("bar -k 4") } )
		assert(lines.any?{ |l| l.include?("bar -k 3") } )
	end

	def test_multipleExecutions
		cmd = "#{$minstructor} \"#{@@dummyScriptFile} -key0 a -imp=range(2) " \
		      "-blao linspace(0.4, 12, 3)\" -f -n 3"
		%x(#{cmd})

		f = File.open(@@dummyScriptLogFile, "r")
		log = f.read()
		f.close()
		File.delete(@@dummyScriptLogFile)
		lines = log.lines.map {|l| l.chomp} # remove \n
		assert_equal(3, lines.count("-key0 a -imp=1 -blao 0.4"))
	end

	def test_defaultOutputFileNaming
		cmd = "#{$minstructor} \"#{@@dummyScriptFile} -key0 [ a,  3] " \
		      "logspace(1,3,3)\" -f -n 3 -o #{$thisDir}"
		out = %x(#{cmd})
		File.delete(@@dummyScriptLogFile)
		for i in (0...18)
			outFileName = "#{$thisDir}/#{@@defaultOutFilePrefix}#{i}.txt"
			assert(File.exist? outFileName)
			File.delete(outFileName)
		end
	end

	def test_verboseOutputFileNaming
		cmd = "#{$minstructor} \"#{@@dummyScriptFile} -key0 [ a,  3] " \
		      "logspace(1,2,2)\" -f -n 2 --verbose-fname -o #{$thisDir}"
		out = %x(#{cmd})
		File.delete(@@dummyScriptLogFile)
		out_file_names = [
			"#{$thisDir}/#{@@defaultOutFilePrefix}0_a_10.0.txt",
			"#{$thisDir}/#{@@defaultOutFilePrefix}1_a_100.0.txt",
			"#{$thisDir}/#{@@defaultOutFilePrefix}2_3_10.0.txt",
			"#{$thisDir}/#{@@defaultOutFilePrefix}3_3_100.0.txt",
			"#{$thisDir}/#{@@defaultOutFilePrefix}4_a_10.0.txt",
			"#{$thisDir}/#{@@defaultOutFilePrefix}5_a_100.0.txt",
			"#{$thisDir}/#{@@defaultOutFilePrefix}6_3_10.0.txt",
			"#{$thisDir}/#{@@defaultOutFilePrefix}7_3_100.0.txt"
		]
		for i in (0...8)
			assert(File.exist? out_file_names[i])
			File.delete(out_file_names[i])
		end
	end

	def test_outputFilePrefix
		cmd = "#{$minstructor} \"#{@@dummyScriptFile} -key0 " \
		      "range(2)range(2)\" -f -n 3 -o #{$thisDir}/myoutputprefix"
		%x(#{cmd})

		File.delete(@@dummyScriptLogFile)
		for i in (0...12)
			outFileName = "#{$thisDir}/myoutputprefix#{i}.txt"
			assert(File.exist? outFileName)
			File.delete(outFileName)
		end
	end

	def test_outputFileNumeration
		cmd = "#{$minstructor} \"#{@@dummyScriptFile} -key0 " \
		      "range(2)range(2)\" -f -n 3 -o #{$thisDir}"

		(0...2).each { %x(#{cmd}) }

		File.delete(@@dummyScriptLogFile)
		(0...24).each do |i|
			outFileName = "#{$thisDir}/#{@@defaultOutFilePrefix}#{i}.txt"
			assert(File.exist? outFileName)
			File.delete(outFileName)
		end
	end

	def test_outputFileNotOverwrite
		# Create a dummy file
		tmpFile = "#{$thisDir}/#{@@defaultOutFilePrefix}4687.txt"
		`touch #{tmpFile}`

		# the output file name must start with 4688
		%x(#{$minstructor} "#{@@dummyScriptFile} -key0 range(2)range(2)" -f -n 3 -o #{$thisDir})

		File.delete(@@dummyScriptLogFile)
		(4687..4687 + 2 * 2 * 3).each do |i|
			outFileName = "#{$thisDir}/#{@@defaultOutFilePrefix}#{i}.txt"
			assert(File.exist? outFileName)
			File.delete(outFileName)
		end
	end
end
