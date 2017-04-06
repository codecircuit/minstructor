#!/usr/bin/ruby

require 'test/unit'

# This test should check the functionality of the
# Command Line Interface by simulating a user interaction
# with the mcollector.

$mcollector = "../mcollector.rb"
$dataDirPrefix = "./mcollector/data/"

class TestCLI < Test::Unit::TestCase

	def test_equalAssignedKeywords
		dataDir = $dataDirPrefix + "simple-equal-assignment"
		# The lines which must be in the correct output
		lines = ["-86748,+0.6874e-08,foo,00.68748",
		         "1654,-0.468e-100,bar,-060.684",
		         "0165498,38.4e+1,BAAZ,+7.065",
		         "-16846,1.468e7,foota,-1886.0648461"]
		# the head of the CSV output
		head = "important-key7,importantKey8,stringKey,floatKey"

		# the mcollector should output the CSV table to stdout
		# if we do not specify an output file
		actualResult = %x(#{$mcollector} -d #{dataDir} \
		                  -k important-key7,importantKey8,stringKey,floatKey)
		assert(actualResult.lines()[0].include?(head))
		lines.each do |l|
			assert(actualResult.include?(l))
		end
	end
	
	def test_colonAssignedKeywords
		dataDir = $dataDirPrefix + "simple-colon-assignment"
		# The lines which must be in the correct output
		lines = ["-86748,+0.6874e-08,foo,00.68748",
		         "1654,-0.468e-100,bar,-060.684",
		         "0165498,38.4e+1,BAAZ,+7.065",
		         "-16846,1.468e7,foota,-1886.0648461"]
		# the head of the CSV output
		head = "important-key7,importantKey8,stringKey,floatKey"

		# the mcollector should output the CSV table to stdout
		# if we do not specify an output file
		actualResult = %x(#{$mcollector} -d #{dataDir} \
		                  -k important-key7,importantKey8,stringKey,floatKey)
		assert(actualResult.lines()[0].include?(head))
		lines.each do |l|
			assert(actualResult.include?(l))
		end
	end

	def test_arrowAssignedKeywords
		dataDir = $dataDirPrefix + "simple-arrow-assignment"
		# The lines which must be in the correct output
		lines = ["-86748,+0.6874e-08,foo,00.68748",
		         "1654,-0.468e-100,bar,-060.684",
		         "0165498,38.4e+1,BAAZ,+7.065",
		         "-16846,1.468e7,foota,-1886.0648461"]
		# the head of the CSV output
		head = "important-key7,importantKey8,stringKey,floatKey"

		# the mcollector should output the CSV table to stdout
		# if we do not specify an output file
		actualResult = %x(#{$mcollector} -d #{dataDir} \
		                  -k important-key7,importantKey8,stringKey,floatKey)
		assert(actualResult.lines()[0].include?(head))
		lines.each do |l|
			assert(actualResult.include?(l))
		end
	end

end