require_relative 'helper'

class TestDebian__Ar < MiniTest::Test

  def setup
    @ruby = Dir["/var/cache/apt/archives/ruby2.0_*.deb"]
    if @ruby.empty?
      flunk("no ruby package in /var/cache/apt/archives")
    end
  end
  def test_list
    @ruby.each {|deb|
      assert_equal(['debian-binary','control.tar.gz','data.tar.xz'],
                   Debian::Ar.new(deb).list.collect {|arf| arf.name })
    }
  end

  def test_each_file
    @ruby.each {|deb|
      lists = ['debian-binary','control.tar.gz','data.tar.xz']
      Debian::Ar.new(deb).each_file {|name,io|
        assert_equal(lists[0], name)
        if name == 'debian-binary'
          assert_equal("2.0\n", io.read)
        end
        assert_equal(0, io.stat.uid)
        assert_equal(0, io.stat.gid)
        assert_equal(0100644, io.stat.mode)
        lists.shift
      }
    }
  end

  def test_open
    @ruby.each {|deb|
      ar = Debian::Ar.new(deb)
      assert_instance_of Debian::Ar::ArFile, ar.open("debian-binary")
      assert_equal("2.0\n", ar.open("debian-binary").read)
      assert_instance_of Debian::Ar::ArFile, ar.open("control.tar.gz")
      assert_instance_of Array, ar.open("data.tar.gz")
    }
  end
end
