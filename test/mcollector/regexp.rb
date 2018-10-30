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
			assert(!str.match?(/^#{$numReg}$/))
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
	values.zip(units).each_with_index do |pair,i|
			q = pair.join()
			reg = /^#{$quantityReg}$/
			assert(q.match?(reg))
			md = q.match(reg)
			assert(md.captures.length == 1)
			assert_equal(md.captures[0], pair[0]) # the capture group must match
			assert(pair[0].match?(reg)) # only the number must match too
		end
	end

	def test_quotationReg
		quotations = [
			'"fooo    bar	barz"',
			'"GTX 1070"',
			'"Lorem ipsum "'
		]

		quotations.each do |q|
			reg = /^#{$quotationReg}$/
			assert(q.match?(reg))
		end

		noQuotations = [
			'" uiae uie uiae ',
			'iaeuiae " uiae ',
			'uiaeuie"',
			'"uie"uiae"'
		]

		noQuotations.each do |nq|
			reg = /^#{$quotationReg}$/
			assert(!nq.match?(reg))
		end
	end

	def test_valReg
		strValues = [
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
			'"fooo    bar	barz"',
			'"GTX 1070"',
			'"Lorem ipsum "'
		]

		strValues.each do |v|
			assert(v.match?($valReg))
			md = v.match($valReg)
		end

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

		values.zip(units).each_with_index do |pair,i|
			q = pair.join()
			#reg = /^#{$quantityReg}$/
			assert(q.match?($valReg))
			md = q.match($valReg)
			# now take the first non nil capture
			assert_equal(pair[0], md.captures.select { |c| c != nil}[0])
		end
	end

	def test_keyValueReg
		str = <<-eos
			uditra en Keyword0 = 1654GB/s uditae
			   \t uitae FooBar: "bar baz"
			   - other IMPORTANT    ---->   +61.65e-77Units uditar
			naed turl nedut rnle dtune dluvtr ned
			IMPORTANT but without link symbol
			 SomeInt = 465768 
			 TakeWithUnits = "9981MEGAUNIT"
			   again but not recognized FooBar: "nope"
			   someK   ==>  00.1234
		eos

		check = ->(key, expectedValue) {
			md = str.match(getKeyValueReg(key))
			assert_equal(expectedValue, md["value"])
		}

		key2val = {
			"Keyword0" => "1654",
			"FooBar" => '"bar baz"',
			"IMPORTANT" => "+61.65e-77",
			"SomeInt" => "465768",
			"TakeWithUnits" => '"9981MEGAUNIT"',
			"someK" => "00.1234",
		}

		key2val.each_pair do |key, val|
			check.call(key, val)
		end

	end

end
