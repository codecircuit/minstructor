#!/usr/bin/ruby

require 'test/unit'

# This test should check the functionality of the
# Command Line Interface by simulating a user interaction
# with the mcollector. In particular

$this_dir = File.dirname(File.expand_path(__FILE__))
$mcollector = "#{$this_dir}/../../mcollector.rb"
$data_dir_pre = "#{$this_dir}/data/"

class TestCLIAutoKeywordDetection < Test::Unit::TestCase
	def test_mixedAssignment
		data_dir = $data_dir_pre + "mixed-assignment"
		# The lines which must be in the correct output
		lines = ["-86748,+0.6874e-08,foo,00.68748",
		         "1654,-0.468e-100,bar,-060.684",
		         "0165498,38.4e+1,BAAZ,+7.065",
		         "-16846,1.468e7,foota,-1886.0648461"]
		# the head of the CSV output
		head = "important-key7,importantKey8,stringKey,floatKey"

		# the mcollector should output the CSV table to stdout
		# if we do not specify an output file
		actual_result = %x(#{$mcollector} #{data_dir}/*.txt)
		assert(actual_result.lines()[0].include?(head))
		lines.each do |l|
			assert(actual_result.include?(l))
		end
	end

	def test_singleBlacklistKeyword
		data_dir = $data_dir_pre + "mixed-assignment"
		# The lines which must be in the correct output
		lines = ["-86748,foo,00.68748",
		         "1654,bar,-060.684",
		         "0165498,BAAZ,+7.065",
		         "-16846,foota,-1886.0648461"]
		# the head of the CSV output
		head = "important-key7,stringKey,floatKey"

		# the mcollector should output the CSV table to stdout
		# if we do not specify an output file
		actual_result = %x(#{$mcollector} -i importantKey8 #{data_dir}/*.txt)
		assert(actual_result.lines()[0].include?(head))
		lines.each do |l|
			assert(actual_result.include?(l))
		end
	end

	def test_multipleBlacklistKeyword
		data_dir = $data_dir_pre + "mixed-assignment"
		# The lines which must be in the correct output
		lines = ["-86748,foo",
		         "1654,bar",
		         "0165498,BAAZ",
		         "-16846,foota"]
		# the head of the CSV output
		head = "important-key7,stringKey"

		# the mcollector should output the CSV table to stdout
		# if we do not specify an output file
		actual_result = %x(#{$mcollector} -i importantKey8,floatKey #{data_dir}/*.txt)
		assert(actual_result.lines()[0].include?(head))
		lines.each do |l|
			assert(actual_result.include?(l))
		end
	end
	
	def test_newlineIgnore
		data_dir = $data_dir_pre + "newline-ignore"
		actual_result = `#{$mcollector} #{data_dir}/*.txt`
		assert(!actual_result.include?("Result"))
	end

	def test_doubleColonIgnore
		data_dir = $data_dir_pre + "error"
		actual_result = `#{$mcollector} #{data_dir}/*.txt`
		assert(!actual_result.include?("what"))
		assert(!actual_result.include?("donotlistme"))
		assert(!actual_result.include?(":"))
		assert(!actual_result.include?("Some"))
	end

	def test_dateDetection
		data_dir = $data_dir_pre + "date"
		actual_result = `#{$mcollector} #{data_dir}/*.txt`
		assert(actual_result.include?("2017-08-12"))
	end

	def test_weirdKeywords
		data_dir = $data_dir_pre + "whitespace-keywords"
		# The lines which must be in the correct output
		lines = ['"sleep 1",0.10,2,3,4,1764,5,6,7',
		         '"sleep 2",0.20,8,9,10,1800,11,12,13']
		# the head of the CSV output
		head = "Command being timed," +
			"User time (seconds)," +
			"Percent of CPU this job got," +
			"Average unshared data size (kbytes)," +
			"Average total size (kbytes)," +
			"Maximum resident set size (kbytes)," +
			"Major (requiring I/O) page faults," +
			"Swaps," +
			"File system inputs"

		# the mcollector should output the CSV table to stdout
		# if we do not specify an output file
		actual_result = %x(#{$mcollector} -w  #{data_dir}/*.txt)
		assert(actual_result.lines()[0].include?(head))
		lines.each do |l|
			assert(actual_result.include?(l))
		end
	end
end
