require 'runit/testcase'
require 'runit/cui/testrunner'

$LOAD_PATH.unshift('../lib')
require '../lib/debian.rb'

class TestDebian__Status < RUNIT::TestCase
  def test_s_new
    s = Debian::Status.new
    assert((s['dpkg'].data.find { |f| f == '/usr/bin/dpkg' }) != nil)
  end
  #
  #  def test_s_parse
  #    assert_fail("untested")
  #  end
  #
  #  def test_s_parseAptLine
  #    assert_fail("untested")
  #  end

  #  def test_s_parseArchiveFile
  #    assert_fail("untested")
  #  end
end

if $PROGRAM_NAME == __FILE__
  if ARGV.empty?
    suite = TestDebian__Status.suite
  else
    suite = RUNIT::TestSuite.new
    ARGV.each do |testmethod|
      suite.add_test(TestDebian__Status.new(testmethod))
    end
  end
  RUNIT::CUI::TestRunner.run(suite)
end
