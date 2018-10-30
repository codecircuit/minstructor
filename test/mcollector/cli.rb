#!/usr/bin/ruby

require 'test/unit'

# This test should check the functionality of the
# Command Line Interface by simulating a user interaction
# with the mcollector.

$thisDir = File.dirname(File.expand_path(__FILE__))
$mcollector = "#{$thisDir}/../../mcollector.rb"
$dataDirPrefix = "#{$thisDir}/data/"

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
		actualResult = %x(#{$mcollector} #{dataDir}/*.txt\
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
		actualResult = %x(#{$mcollector} #{dataDir}/*.txt\
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
		actualResult = %x(#{$mcollector} #{dataDir}/*.txt\
		                  -k important-key7,importantKey8,stringKey,floatKey)
		assert(actualResult.lines()[0].include?(head))
		lines.each do |l|
			assert(actualResult.include?(l))
		end
	end

	def test_nokeywords
		dataDir = $dataDirPrefix + "no-keywords"
		actualResult = %x(#{$mcollector} #{dataDir}/*.txt\
		                  -k key0,key1)
		expReg = /(?:N\/A){2},.*\/file[01]\.txt/
		assert(actualResult.include?("key0,key1"))
		md = actualResult.match(expReg)
	end

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
		actualResult = %x(#{$mcollector} #{dataDir}/*.txt\
		                  -k important-key7,importantKey8,stringKey,floatKey)
		assert(actualResult.lines()[0].include?(head))
		lines.each do |l|
			assert(actualResult.include?(l))
		end
	end

	def test_longKeysWithWhitespace
		dataDir = $dataDirPrefix + "long-keys-with-whitespace"
		# The lines which must be in the correct output
		lines = ["baz,quux",
		         "quuz,corge"]
		# the head of the CSV output
		head = "this is the long key,another key(with brackets)"

		actualResult = %x(#{$mcollector} #{dataDir}/*.txt\
		                  -k "this is the long key","another key(with brackets)")
		assert(actualResult.lines()[0].include?(head))
		lines.each do |l|
			assert(actualResult.include?(l))
		end
	end
end
