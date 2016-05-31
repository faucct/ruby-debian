#!/usr/bin/ruby -- # -*- ruby -*-

require 'runit/testsuite'
require 'runit/cui/testrunner'
require 'getoptlong'

$LOAD_PATH.unshift('../lib')

opts = GetoptLong.new(
  ['--output', '-o', GetoptLong::REQUIRED_ARGUMENT],
  ['--quiet', '-q', GetoptLong::NO_ARGUMENT],
  ['--help', '-h', GetoptLong::NO_ARGUMENT]
)

outfile = '-'
opts.each do |opt, val|
  case opt
  when '--output' then $stdout = open(val, 'w'); outfile = val
  when '--quiet' then RUNIT::CUI::TestRunner.quiet_mode = true
  when '--help' then
    $stderr.puts "usage: #{$PROGRAM_NAME} [-o file] [-q] [-h]"
    exit 1
  end
end

Dir['test*.rb'].each do |t|
  next if t == __FILE__
  require t
end

suite = RUNIT::TestSuite.new
ObjectSpace.each_object(Class) do |klass|
  suite.add_test(klass.suite) if klass.ancestors.include?(RUNIT::TestCase)
end
RUNIT::CUI::TestRunner.run(suite)
if outfile != '-'
  $stdout.close
  IO.readlines(outfile).each do |line|
    line.chomp!
    if /^Errors:/ =~ line
      $stderr.puts "#{line}: See more detail in #{outfile}"
    elsif /^Failures:/ =~ line
      $stderr.puts "#{line}: See more detail in #{outfile}"
    elsif /^OK/ =~ line
      $stderr.puts line.to_s
    end
  end
end
