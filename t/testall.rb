#!/usr/bin/ruby -- # -*- ruby -*-

require 'runit/testsuite'
require 'runit/cui/testrunner'
require 'getoptlong'

$:.unshift("../lib")

opts = GetoptLong.new(
		      ['--output', '-o', GetoptLong::REQUIRED_ARGUMENT],
		      ['--quiet', '-q', GetoptLong::NO_ARGUMENT],
		      ['--help', '-h', GetoptLong::NO_ARGUMENT])

outfile = '-'
opts.each {|opt, val|
  case opt
  when "--output" then $stdout = open(val, "w"); outfile = val
  when "--quiet" then RUNIT::CUI::TestRunner.quiet_mode = true
  when "--help" then
    $stderr.puts "usage: #{$0} [-o file] [-q] [-h]"
    exit 1
  end
}

Dir["test*.rb"].each {|t|
  next if t == __FILE__
  require t
}

suite = RUNIT::TestSuite.new
ObjectSpace.each_object(Class) {|klass|
  if klass.ancestors.include?(RUNIT::TestCase)
    suite.add_test(klass.suite)
  end
}
RUNIT::CUI::TestRunner.run(suite)
if outfile != '-'
  $stdout.close
  IO.readlines(outfile).each {|line|
    line.chomp!
    if /^Errors:/ =~ line
      $stderr.puts "#{line}: See more detail in #{outfile}"
    elsif /^Failures:/ =~ line
      $stderr.puts "#{line}: See more detail in #{outfile}"
    elsif /^OK/ =~ line
      $stderr.puts "#{line}"
    end
  }
end
  
