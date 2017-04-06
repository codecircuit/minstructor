#!/usr/bin/ruby

require 'test/unit'

require_relative '../../mcollector.rb'

class TestDataFileNameIterator < Test::Unit::TestCase

	def test_iteration

		dpath = "mcollector/data/data-file-iterator"
		it = DataFileNameIterator.new(dpath, ".txt")

		dataFileNames = [
			"data0.txt",
			"data1.txt",
			"file-a.txt",
			"file-b.txt"
		]

		it.each do |fpth|
			fname = File.basename(fpth)
			assert(dataFileNames.include?(fname))
			dataFileNames.delete(fname)
		end
		assert(dataFileNames.empty?)
	end
end
