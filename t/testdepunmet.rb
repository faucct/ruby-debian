require 'runit/testcase'
require 'runit/cui/testrunner'

$LOAD_PATH.unshift('../lib')
require '../lib/debian.rb'

class TestDebian__Dep__Unmet < RUNIT::TestCase
  def setup
    dep = Debian::Dep::Term.new('w3m')
    assert_not_nil(dep)
    deb = Debian::Deb.new(IO.readlines('d/w3m-ssl_0.2.1-1.f').join(''))
    assert_not_nil(deb)
    @unmet = Debian::Dep::Unmet.new(dep, deb)
  end

  def test_deb
    deb = Debian::Deb.new(IO.readlines('d/w3m-ssl_0.2.1-1.f').join(''))
    assert_equals(deb, @unmet.deb)
  end

  def test_dep
    assert_equals(Debian::Dep::Term.new('w3m'), @unmet.dep)
  end

  def test_package
    assert_nil(@unmet.package)
  end

  def test_package=
    @unmet.package = 'w3m-el'
    assert_equals('w3m-el', @unmet.package)
    assert_exception(Debian::DepError) { @unmet.package = 'w3m' }
  end

  def test_relation
    assert_nil(@unmet.relation)
  end

  def test_relation=
    @unmet.relation = 'depends'
    assert_equals('depends', @unmet.relation)
    assert_exception(Debian::DepError) { @unmet.relation = 'recommends' }
  end

  def test_to_s
    assert_equals('w3m unmet w3m-ssl 0.2.1-1 (provides w3m)', @unmet.to_s)
    @unmet.package = 'w3m-ssl'
    assert_equals('w3m-ssl w3m unmet w3m-ssl 0.2.1-1 (provides w3m)',
                  @unmet.to_s)
    @unmet.relation = 'depends'
    assert_equals('w3m-ssl depends w3m unmet w3m-ssl 0.2.1-1 (provides w3m)',
                  @unmet.to_s)
  end

  #  def test_s_new
  #	???
  #  end
end

if $PROGRAM_NAME == __FILE__
  if ARGV.empty?
    suite = TestDebian__Dep__Unmet.suite
  else
    suite = RUNIT::TestSuite.new
    ARGV.each do |testmethod|
      suite.add_test(TestDebian__Dep__Unmet.new(testmethod))
    end
  end
  RUNIT::CUI::TestRunner.run(suite)
end
