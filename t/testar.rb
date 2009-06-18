require 'runit/testcase'
require 'runit/cui/testrunner'

$:.unshift("../lib")
require 'debian/ar'

class TestDebian__Ar < RUNIT::TestCase

  def setup
    @ruby = Dir["/var/cache/apt/archives/ruby_1.6*.deb"]
    if @ruby.empty?
      assert_fail("no ruby package in /var/cache/apt/archives")
    end
  end
  def test_list
    @ruby.each {|deb|
      assert_equals(['debian-binary','control.tar.gz','data.tar.gz'],
		   Debian::Ar.new(deb).list.collect {|arf| arf.name })
    }
  end

  def test_each_file
    @ruby.each {|deb|
      lists = ['debian-binary','control.tar.gz','data.tar.gz']
      Debian::Ar.new(deb).each_file {|name,io|
	assert_equals(lists[0], name)
	if name == 'debian-binary'
	  assert_equals("2.0\n", io.read)
	end
	assert_equals(0, io.stat.uid)
	assert_equals(0, io.stat.gid)
	assert_equals(0100644, io.stat.mode)
	lists.shift
      }
    }
  end

  def test_open
    @ruby.each {|deb|
      ar = Debian::Ar.new(deb)
      assert_not_nil(ar.open("debian-binary"))
      assert_equals("2.0\n", ar.open("debian-binary").read)
      assert_not_nil(ar.open("control.tar.gz"))
      assert_not_nil(ar.open("data.tar.gz"))
    }
  end
end

if $0 == __FILE__
  if ARGV.size == 0
    suite = TestDebian__Ar.suite
  else
    suite = RUNIT::TestSuite.new
    ARGV.each do |testmethod|
      suite.add_test(TestDebian__Ar.new(testmethod))
    end
  end
  RUNIT::CUI::TestRunner.run(suite)
end
