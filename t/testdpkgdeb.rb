require_relative 'helper'

class TestDebian__DpkgDeb < MiniTest::Test

  def setup
    @ruby = Dir["/var/cache/apt/archives/ruby2.0_*.deb"]
    if @ruby.empty?
      flunk("no ruby package in /var/cache/apt/archives")
    end
    @libs = Dir["/usr/lib/libc.*"]
    if @libs.empty?
      flunk("no libc in /usr/lib")
    end
  end
  def test_deb?
    @ruby.each {|deb|
      assert(Debian::DpkgDeb.deb?(deb))
    }
    @libs.each {|lib|
      assert(! Debian::DpkgDeb.deb?(lib))
    }
  end
  def test_assert_deb?
    @ruby.each {|deb|
      assert_no_raises(Debian::Error) {Debian::DpkgDeb.assert_deb?(deb)}
    }
    @libs.each {|lib|
      assert_raises(Debian::Error) {! Debian::DpkgDeb.assert_deb?(lib)}
    }
  end

  def test_control
    ENV["LANG"] = 'C'
    @ruby.each {|deb|
      c = []
      IO.popen("dpkg -I #{deb}") {|fp|
	fp.each {|line|
	  line.chomp!
	  if /^\s+\d+\sbytes,\s+\d+\s+lines\s+\*?\s*(\S+).*/ =~ line
	    c.push($1)
	  end
	}
      }
      assert_equal(c.sort, Debian::DpkgDeb.control(deb).sort)
    }
  end
  def test_data
    @ruby.each {|deb|
      d = []
      IO.popen("dpkg --fsys-tarfile #{deb}|tar tf -") {|fp|
	fp.each {|line|
	  line.chomp!
	  d.push(line)
	}
      }
      assert_equal(d, Debian::DpkgDeb.data(deb))
    }
  end

  def test_load
    @ruby.each {|deb|
      de = Debian::DpkgDeb.load(deb)
      assert_equal(deb, de.filename)
    }
  end

end
