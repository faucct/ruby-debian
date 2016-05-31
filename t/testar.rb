require 'runit/testcase'
require 'runit/cui/testrunner'

$LOAD_PATH.unshift('../lib')
require 'debian/ar'

class TestDebian__Ar < RUNIT::TestCase
  def setup
    @ruby = Dir['/var/cache/apt/archives/ruby_1.6*.deb']
    assert_fail('no ruby package in /var/cache/apt/archives') if @ruby.empty?
  end

  def test_list
    @ruby.each do |deb|
      assert_equals(['debian-binary', 'control.tar.gz', 'data.tar.gz'],
                    Debian::Ar.new(deb).list.collect(&:name))
    end
  end

  def test_each_file
    @ruby.each do |deb|
      lists = ['debian-binary', 'control.tar.gz', 'data.tar.gz']
      Debian::Ar.new(deb).each_file do |name, io|
        assert_equals(lists[0], name)
        assert_equals("2.0\n", io.read) if name == 'debian-binary'
        assert_equals(0, io.stat.uid)
        assert_equals(0, io.stat.gid)
        assert_equals(0100644, io.stat.mode)
        lists.shift
      end
    end
  end

  def test_open
    @ruby.each do |deb|
      ar = Debian::Ar.new(deb)
      assert_not_nil(ar.open('debian-binary'))
      assert_equals("2.0\n", ar.open('debian-binary').read)
      assert_not_nil(ar.open('control.tar.gz'))
      assert_not_nil(ar.open('data.tar.gz'))
    end
  end
end

if $PROGRAM_NAME == __FILE__
  if ARGV.empty?
    suite = TestDebian__Ar.suite
  else
    suite = RUNIT::TestSuite.new
    ARGV.each do |testmethod|
      suite.add_test(TestDebian__Ar.new(testmethod))
    end
  end
  RUNIT::CUI::TestRunner.run(suite)
end
