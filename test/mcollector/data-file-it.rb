#!/usr/bin/ruby

require 'test/unit'

require_relative '../../mcollector.rb'

class TestDataFileIterator < Test::Unit::TestCase

	def test_pathIteration

		dpath = "mcollector/data/data-file-iterator"
		it = DataFileIterator.new(dpath, ".txt")

		dataFileNames = [
			"data0.txt",
			"data1.txt",
			"file-a.txt",
			"file-b.txt"
		]

		it.each_pth do |fpth|
			fname = File.basename(fpth)
			assert(dataFileNames.include?(fname))
			dataFileNames.delete(fname)
		end
		assert(dataFileNames.empty?)

	end

	def test_contentIteration
		dpath = "mcollector/data/data-file-iterator"
		it = DataFileIterator.new(dpath, ".txt")

		it.each_content_with_pth do |c, fpth|
			f = File.open(fpth)
			content = f.read()
			f.close()
			fname = File.basename(fpth)
			assert(content == c)
		end
	end

end
