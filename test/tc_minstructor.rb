#!/usr/bin/ruby

require 'test/unit'
require_relative '../minstructor'

class TestRangeFunctions < Test::Unit::TestCase

	def test_range
		assert_equal([0,1,2], range(3))
#		assert_equal()
	end
end

