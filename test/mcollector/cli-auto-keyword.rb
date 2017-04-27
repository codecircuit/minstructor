#!/usr/bin/ruby

require 'test/unit'

# This test should check the functionality of the
# Command Line Interface by simulating a user interaction
# with the mcollector. In particular

$thisDir = File.dirname(File.expand_path(__FILE__))
$mcollector = "#{$thisDir}/../../mcollector.rb"
$dataDirPrefix = "#{$thisDir}/data/"

class TestCLIAutoKeywordDetection < Test::Unit::TestCase
	def test_mixedAssignment
		dataDir = $dataDirPrefix + "mixed-assignment"
		# The lines which must be in the correct output
		lines = ["-86748,+0.6874e-08,foo,00.68748",
		         "1654,-0.468e-100,bar,-060.684",
		         "0165498,38.4e+1,BAAZ,+7.065",
		         "-16846,1.468e7,foota,-1886.0648461"]
		# the head of the CSV output
		head = "important-key7,importantKey8,stringKey,floatKey"

		# the mcollector should output the CSV table to stdout
		# if we do not specify an output file
		actualResult = %x(#{$mcollector} #{dataDir}/*.txt)
		assert(actualResult.lines()[0].include?(head))
		lines.each do |l|
			assert(actualResult.include?(l))
		end
	end

	def test_singleBlacklistKeyword
		dataDir = $dataDirPrefix + "mixed-assignment"
		# The lines which must be in the correct output
		lines = ["-86748,foo,00.68748",
		         "1654,bar,-060.684",
		         "0165498,BAAZ,+7.065",
		         "-16846,foota,-1886.0648461"]
		# the head of the CSV output
		head = "important-key7,stringKey,floatKey"

		# the mcollector should output the CSV table to stdout
		# if we do not specify an output file
		actualResult = %x(#{$mcollector} -i importantKey8 #{dataDir}/*.txt)
		assert(actualResult.lines()[0].include?(head))
		lines.each do |l|
			assert(actualResult.include?(l))
		end
	end

	def test_multipleBlacklistKeyword
		dataDir = $dataDirPrefix + "mixed-assignment"
		# The lines which must be in the correct output
		lines = ["-86748,foo",
		         "1654,bar",
		         "0165498,BAAZ",
		         "-16846,foota"]
		# the head of the CSV output
		head = "important-key7,stringKey"

		# the mcollector should output the CSV table to stdout
		# if we do not specify an output file
		actualResult = %x(#{$mcollector} -i importantKey8,floatKey #{dataDir}/*.txt)
		assert(actualResult.lines()[0].include?(head))
		lines.each do |l|
			assert(actualResult.include?(l))
		end
	end
end
