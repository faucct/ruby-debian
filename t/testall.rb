#!/usr/bin/ruby
# -*- ruby -*-

require_relative 'helper'
require 'getoptlong'

opts = GetoptLong.new(
		      ['--output', '-o', GetoptLong::REQUIRED_ARGUMENT],
		      ['--quiet', '-q', GetoptLong::NO_ARGUMENT],
		      ['--help', '-h', GetoptLong::NO_ARGUMENT])

outfile = '-'
opts.each {|opt, val|
  case opt
  when "--output" then $stdout = open(val, "w"); outfile = val
  when "--quiet" then $VERBOSE = false
  when "--help" then
    $stderr.puts "usage: #{$0} [-o file] [-q] [-h]"
    exit 1
  end
}

Dir[File.join('.', 't', "test*.rb")].each {|t|
  next if t == __FILE__
  require t
}
