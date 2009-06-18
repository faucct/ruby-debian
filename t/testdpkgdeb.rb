require 'runit/testcase'
require 'runit/cui/testrunner'

$:.unshift("../lib")
require '../lib/debian.rb'

class TestDebian__DpkgDeb < RUNIT::TestCase

  def setup
    @ruby = Dir["/var/cache/apt/archives/ruby_1.6*.deb"]
    if @ruby.empty?
      assert_fail("no ruby package in /var/cache/apt/archives")
    end
    @libs = Dir["/usr/lib/libc.*"]
    if @libs.empty?
      assert_fail("no libc in /usr/lib")
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
      assert_no_exception(Debian::Error) {Debian::DpkgDeb.assert_deb?(deb)}
    }
    @libs.each {|lib|
      assert_exception(Debian::Error) {! Debian::DpkgDeb.assert_deb?(lib)}
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
      assert_equals(c.sort, Debian::DpkgDeb.control(deb).sort)
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
      assert_equals(d, Debian::DpkgDeb.data(deb))
    }
  end

  def test_load
    @ruby.each {|deb|
      de = Debian::DpkgDeb.load(deb)
      assert_equals(deb, de.filename)
    }
  end

end

if $0 == __FILE__
  if ARGV.size == 0
    suite = TestDebian__DpkgDeb.suite
  else
    suite = RUNIT::TestSuite.new
    ARGV.each do |testmethod|
      suite.add_test(TestDebian__DpkgDeb.new(testmethod))
    end
  end
  RUNIT::CUI::TestRunner.run(suite)
end
