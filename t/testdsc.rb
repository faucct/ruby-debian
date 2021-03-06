require 'runit/testcase'
require 'runit/cui/testrunner'

$LOAD_PATH.unshift('../lib')
require '../lib/debian.rb'

class TestDebian__Dsc < RUNIT::TestCase
  def setup
    @dsc = [Debian::Dsc.new(IO.readlines('d/w3m_0.2.1-1.dsc').join('')),
            Debian::Dsc.new(IO.readlines('d/w3m_0.2.1-2.dsc').join('')),
            Debian::Dsc.new(IO.readlines('d/w3m-ssl_0.2.1-2.dsc').join(''))]
  end

  def test_binary
    assert_equals(['w3m'], @dsc[0].binary)
    assert_equals(['w3m'], @dsc[1].binary)
    assert_equals(['w3m-ssl'], @dsc[2].binary)
  end

  def test_package
    assert_equals('w3m', @dsc[0].package)
    assert_equals('w3m', @dsc[1].package)
    assert_equals('w3m-ssl', @dsc[2].package)
  end

  def test_version
    assert_equals('0.2.1-1', @dsc[0].version)
    assert_equals('0.2.1-2', @dsc[1].version)
    assert_equals('0.2.1-2', @dsc[2].version)
  end

  #  def test_s_new
  #
  #  end
end

if $PROGRAM_NAME == __FILE__
  if ARGV.empty?
    suite = TestDebian__Dsc.suite
  else
    suite = RUNIT::TestSuite.new
    ARGV.each do |testmethod|
      suite.add_test(TestDebian__Dsc.new(testmethod))
    end
  end
  RUNIT::CUI::TestRunner.run(suite)
end
