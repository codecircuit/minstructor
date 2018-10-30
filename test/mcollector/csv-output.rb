#!/usr/bin/ruby

require 'test/unit'
require 'tempfile'

require_relative '../../mcollector.rb'

class TestCSVOutput < Test::Unit::TestCase

	def test_simple_output

		csvRows = [
			{ "key0" => "foo", "key1" => "bar", "key2" => "468", "data-file-path" => "/pth/1.txt" },
			{ "key0" =>"dumm", "key1" => "baz", "key2" => "132", "data-file-path" => "/pth/2.txt" },
			{ "key0" => "hip", "key1" => "hop", "key2" => "165", "data-file-path" => "/pth/3.txt" },
		]
		keywords = Set.new(["key0", "key1", "key2", "data-file-path"])

		expectedResult = <<-eos
key0,key1,key2,data-file-path
foo,bar,468,/pth/1.txt
dumm,baz,132,/pth/2.txt
hip,hop,165,/pth/3.txt
		eos

		tmpfile= Tempfile.new("csvoutput")
		tmppth = tmpfile.path
		tmpfile.close
		tmpfile.unlink

		outputCSV(tmppth, csvRows, keywords)

		f = File.open(tmppth)
		content = f.read()
		f.close
		File.delete(tmppth)
		assert_equal(content, expectedResult)

	end

end
