#!/usr/bin/ruby

require 'test/unit'

require_relative '../../mcollector.rb'

$thisDir = File.dirname(File.expand_path(__FILE__))
$dpath = "#{$thisDir}/data/data-file-iterator"

class TestDataFileIterator < Test::Unit::TestCase
	def test_pathIteration

		dataFileNames = [
			"data0.txt",
			"data1.txt",
			"file-a.txt",
			"file-b.txt"
		]

		it = DataFileIterator.new(:dfiles => dataFileNames.map { |fn| $dpath + "/" + fn })

		it.each_pth do |fpth|
			fname = File.basename(fpth)
			assert(dataFileNames.include?(fname))
			dataFileNames.delete(fname)
		end
		assert(dataFileNames.empty?)

	end

	def test_contentIteration

		dataFileNames = [
			"data0.txt",
			"data1.txt",
			"file-a.txt",
			"file-b.txt"
		]

		it = DataFileIterator.new(:dfiles => dataFileNames.map { |fn| $dpath + "/" + fn })

		it.each_content_with_pth do |c, fpth|
			f = File.open(fpth)
			content = f.read()
			f.close()
			fname = File.basename(fpth)
			assert(content == c)
		end
	end
end
