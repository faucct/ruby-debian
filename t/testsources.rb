require 'runit/testcase'
require 'runit/cui/testrunner'

$LOAD_PATH.unshift('../lib')
require '../lib/debian.rb'

class TestDebian__Sources < RUNIT::TestCase
  def setup
    @ss = [Debian::Sources.new('d/sid_Sources'),
           Debian::Sources.new('d/non-US_sid_Sources')]
  end

  def test_s_new
    @ss[0].each { |_p, s|  assert_equals(Debian::Dsc, s.class) }
    @ss[1].each { |_p, s|  assert_equals(Debian::Dsc, s.class) }
  end

  #  def test_s_parse
  #
  #  end

  #  def test_s_parseAptLine
  #
  #  end

  #  def test_s_parseArchiveFile
  #
  #  end
end

if $PROGRAM_NAME == __FILE__
  if ARGV.empty?
    suite = TestDebian__Sources.suite
  else
    suite = RUNIT::TestSuite.new
    ARGV.each do |testmethod|
      suite.add_test(TestDebian__Sources.new(testmethod))
    end
  end
  RUNIT::CUI::TestRunner.run(suite)
end
