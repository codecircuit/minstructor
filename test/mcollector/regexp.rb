#!/usr/bin/ruby


require 'test/unit'
require_relative '../../mcollector.rb'

class TC_regexp < Test::Unit::TestCase

	def test_numReg
		strNumbers = [
			"06546",
			"-1657",
			"+654687",
			"-0546.4068",
			"+64764.1684",
			"6157.7687",
			"164.165e+154",
			"+16.468e-16",
			"-000.635e-1067",
			"1.16e+2",
			"0.3e-2",
			"1.4e+00",
			"1",
			"0",
		]

		strNumbers.each do |str|
			# here we add beginning and end to the regex
			# to check against the WHOLE string. Otherwise
			# "-.657" would match with "657"
			assert(str.match? /^#{$numReg}$/)
		end

		notStrNumbers = [
			"foo",
			".6876",
			"0684.",
			"+.674",
			"-.65767",
			".",
			"654.",
			".654",
			"+.6",
			"16a-67"
		]

		notStrNumbers.each do |str|
			# here we add beginning and end to the regex
			# to check against the WHOLE string. Otherwise
			# "-.657" would match with "657"
			assert(str.match?(/^#{$numReg}$/) != true)
		end
	end

	def test_quantityReg
		values = [
			"67",
			"+0610.6744e+676",
			"46547",
			"67.16E+77"
		]
		units = [
			"GB/s",
			"s",
			"Byte",
			"myunit"
		]
		quantities.each do |q|
			reg = /^#{$quantityReg}$/
			assert(q.match?(reg))
			md = q.match(reg)
			puts "md.length = #{md.length}"
			assert(md.captures.length == 1)
			# TODO find a way to iterate over both
			# lists above and join them to generate
			# the correct quantity string
		end
	end
end
