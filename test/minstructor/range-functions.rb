require 'test/unit'
require_relative '../../minstructor.rb'

$thisDir = File.dirname(File.expand_path(__FILE__))
$dataDirPrefix = "#{$thisDir}/data/"

class TestRangeFunctions < Test::Unit::TestCase

	def test_combinations
		l = [[[1], [2, 3], 4]]
		c = combinations(l)
		s = [[1, 2, 4], [1, 3, 4]]
		assert_equal(s, c)

		l = [[[1], [2, 3]]]
		c = combinations(l)
		s = [[1, 2], [1, 3]]
		assert_equal(s, c)

		l = [[[1], [2]]]
		c = combinations(l)
		assert_equal([[1, 2]], c)
	end

	def test_range
		assert_equal([0,1,2], range(3))
		assert_equal([3,4,5], range(3,6))
		assert_equal([3,1003,2003], range(3,2004,1000))
		assert_raise(RangeError) {range(0, -1)}
		assert_raise(RangeError) {range(0, 0)}
	end

	def test_linspace
		assert_equal([0,-0.25,-0.5,-0.75,-1], linspace(0,-1,5))
		assert_equal([6,6.25,6.5,6.75,7], linspace(6,7,5))
		assert_equal([1,1,1,1,1], linspace(1,1,5))
		assert_raise(RangeError) {linspace(3,4,0)}
		assert_raise(RangeError) {linspace(3,4,-3)}
	end

	def test_logspace
		assert_equal([2,4,8], logspace(1,3,3,2))
		assert_equal([10,100,1000], logspace(1,3,3))
		assert_equal([1000,10], logspace(3,1,2))
		assert_equal([8,0.5], logspace(3,-1,2,2))
		assert_equal([16,25.3984,40.3175,64], logspace(4,6,4,2,4))
		assert_raise(RangeError) {logspace(1,3,0)}
		assert_raise(RangeError) {logspace(1,3,-1)}
	end

	def test_fromfile
		out0 = fromfile("#{$dataDirPrefix}fromfile0.txt")
		assert_equal(["1", "2", "3"], out0)
		out1 = fromfile("#{$dataDirPrefix}fromfile1.txt")
		assert_equal(["foo bar", "baz qux", "quux quuz"], out1)
	end
end
