#!/usr/bin/ruby

require 'test/unit'

# This test should check the functionality of the
# Command Line Interface by simulating a user interaction
# with the mcollector.
# TODO test key="more words" assignments
# TODO add lorem ipsum

$mcollector = "../mcollector.rb"

class TestCLI < Test::Unit::TestCase

	def test_equalAssignedKeywords
		dataDir = "data/simple-equal-assignment"
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
		assert_equal(head, actualResult.lines()[0].chomp())
		lines.each do |l|
			assert(actualResult.include?(l))
		end
	end
	
	def test_spaceAssignedKeywords
		dataDir = "data/simple-space-assignment"
		# The lines which must be in the correct output
		lines = ["+0.6874e-08,foo,-86748,00.68748",
		         "-0.468e-100,bar,1654,-060.684",
		         "38.4e+1,BAAZ,0165498,+7.065",
		         "1.468e7,foota,-16846,-1886.0648461"]
		# the head of the CSV output
		head = "importantKey8,stringKey,important-key7,floatKey"

		# the mcollector should output the CSV table to stdout
		# if we do not specify an output file
		actualResult = %x(#{$mcollector} -d #{dataDir} \
		                  -k importantKey8,stringKey,important-key7,floatKey)
		assert_equal(head, actualResult.lines()[0].chomp())
		lines.each do |l|
			assert(actualResult.include?(l))
		end
	end

	def test_colonAssignedKeywords
		dataDir = "data/simple-colon-assignment"
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
		assert_equal(head, actualResult.lines()[0].chomp())
		lines.each do |l|
			assert(actualResult.include?(l))
		end
	end

	def test_arrowAssignedKeywords
		dataDir = "data/simple-arrow-assignment"
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
		assert_equal(head, actualResult.lines()[0].chomp())
		lines.each do |l|
			assert(actualResult.include?(l))
		end
	end

end
