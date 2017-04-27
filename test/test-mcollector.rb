#!/usr/bin/ruby

# this file makes it possible to disable
# temporary tests by setting comments in
# front of the require statement

require 'test/unit'
require_relative './mcollector/regexp.rb'
require_relative './mcollector/data-file-it.rb'
require_relative './mcollector/csv-output.rb'
require_relative './mcollector/cli.rb'
require_relative './mcollector/cli-auto-keyword.rb'
