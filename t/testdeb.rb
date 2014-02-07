require_relative 'helper'

class TestDebian__Deb < MiniTest::Test

  def setup
    @deb = [Debian::Deb.new(IO.readlines("d/w3m_0.2.1-1.f").join("")),
            Debian::Deb.new(IO.readlines("d/w3m_0.2.1-2.f").join("")),
            Debian::Deb.new(IO.readlines("d/w3m-ssl_0.2.1-1.f").join("")),
            Debian::Deb.new(IO.readlines("d/w3m-ssl_0.2.1-2.f").join(""))]
  end

  def test_package
    assert_equals("w3m", @deb[0].package)
    assert_equals("w3m", @deb[1].package)
    assert_equals("w3m-ssl", @deb[2].package)
    assert_equals("w3m-ssl", @deb[3].package)
  end

  def test_provides
    assert_equals(['www-browser'], @deb[0].provides)
    assert_equals(['www-browser'], @deb[1].provides)
    assert_equals(['www-browser'], @deb[2].provides)
    assert_equals(['www-browser'], @deb[3].provides)
  end

  def test_source
    assert_equals("w3m", @deb[0].package)
    assert_equals("w3m", @deb[1].package)
    assert_equals("w3m-ssl", @deb[2].package)
    assert_equals("w3m-ssl", @deb[3].package)
  end

  def test_unmet
    p = Debian::Packages.new("d/w3m_met_list")
    puts @deb[0].unmet(p)
    assert_equals([], @deb[0].unmet(p))
  end

  def test_version
    assert_equals("0.2.1-1", @deb[0].version)
    assert_equals("0.2.1-2", @deb[1].version)
    assert_equals("0.2.1-1", @deb[2].version)
    assert_equals("0.2.1-2", @deb[3].version)
  end

  def test_status
    assert_equals("not-installed", @deb[0].status)
  end

  def test_selection
    assert_equals("unknown", @deb[0].selection)
  end

  def test_description
    assert_equals("WWW browsable pager with excellent tables/frames support",
		  @deb[0].description)
  end

  def test_unknown?
    assert(@deb[0].unknown?)
    d = Debian::Deb.new([IO.readlines("d/w3m_0.2.1-1.f"),
			  "Status: unknown ok not-installed\n"].join(""))
    assert(d.unknown?)
  end
  def test_install?
    assert(! @deb[0].installed?)
    d = Debian::Deb.new([IO.readlines("d/w3m_0.2.1-1.f"),
			  "Status: install ok installed\n"].join(""))
    assert(d.install?)
  end
  def test_hold?
    assert(! @deb[0].hold?)
    d = Debian::Deb.new([IO.readlines("d/w3m_0.2.1-1.f"),
			  "Status: hold ok installed\n"].join(""))
    assert(d.hold?)
  end
  def test_deinstall?
    assert(! @deb[0].deinstall?)
    d = Debian::Deb.new([IO.readlines("d/w3m_0.2.1-1.f"),
			  "Status: deinstall ok not-installed\n"].join(""))
    assert(d.deinstall?)
  end
  def test_remove?
    assert(! @deb[0].remove?)
    d = Debian::Deb.new([IO.readlines("d/w3m_0.2.1-1.f"),
			  "Status: deinstall ok not-installed\n"].join(""))
    assert(d.remove?)
  end
  def test_purge?
    assert(! @deb[0].purge?)
    d = Debian::Deb.new([IO.readlines("d/w3m_0.2.1-1.f"),
			  "Status: purge ok not-installed\n"].join(""))
    assert(d.purge?)
  end
  def test_not_installed?
    assert(@deb[0].not_installed?)
    d = Debian::Deb.new([IO.readlines("d/w3m_0.2.1-1.f"),
			  "Status: unknown ok not-installed\n"].join(""))
    assert(d.not_installed?)
  end
  def test_purged?
    assert(@deb[0].purged?)
    d = Debian::Deb.new([IO.readlines("d/w3m_0.2.1-1.f"),
			  "Status: unknown ok not-installed\n"].join(""))
    assert(d.purged?)
  end
  def test_unpacked?
    assert(! @deb[0].unpacked?)
    d = Debian::Deb.new([IO.readlines("d/w3m_0.2.1-1.f"),
			  "Status: install ok unpacked\n"].join(""))
    assert(d.unpacked?)
  end
  def test_half_configured?
    assert(! @deb[0].half_configured?)
    d = Debian::Deb.new([IO.readlines("d/w3m_0.2.1-1.f"),
			  "Status: install reinstreq half-configured\n"].join(""))
    assert(d.half_configured?)
  end
  def test_intalled?
    assert(! @deb[0].installed?)
    d = Debian::Deb.new([IO.readlines("d/w3m_0.2.1-1.f"),
			  "Status: install ok installed\n"].join(""))
    assert(d.installed?)
  end
  def test_half_installed?
    assert(! @deb[0].half_installed?)
    d = Debian::Deb.new([IO.readlines("d/w3m_0.2.1-1.f"),
			  "Status: install reinstreq half-installed\n"].join(""))
    assert(d.half_installed?)
  end
  def test_config_files?
    assert(! @deb[0].config_files?)
    d = Debian::Deb.new([IO.readlines("d/w3m_0.2.1-1.f"),
			  "Status: install ok config-files\n"].join(""))
    assert(d.config_files?)
  end
  def test_config_only?
    assert(! @deb[0].config_only?)
    d = Debian::Deb.new([IO.readlines("d/w3m_0.2.1-1.f"),
			  "Status: install ok config-files\n"].join(""))
    assert(d.config_only?)
  end
  def test_removed?
    assert(@deb[0].removed?)
    d = Debian::Deb.new([IO.readlines("d/w3m_0.2.1-1.f"),
			  "Status: install ok config-files\n"].join(""))
    assert(d.removed?)
  end
  def test_need_fix?
    assert(! @deb[0].need_fix?)
    d = Debian::Deb.new([IO.readlines("d/w3m_0.2.1-1.f"),
			  "Status: install reinstreq half-installed\n"].join(""))
    assert(d.need_fix?)
  end
  def test_need_action?
    assert(! @deb[0].need_action?)
    d = Debian::Deb.new([IO.readlines("d/w3m_0.2.1-1.f"),
			  "Status: install ok not-installed\n"].join(""))
    assert(d.need_action?)
  end

  def test_ok?
    assert(@deb[0].ok?)
  end

  def check_apt_cache
    @ruby = Dir["/var/cache/apt/archives/ruby_1.6*.deb"]
    if @ruby.empty?
      flunk("no ruby package in /var/cache/apt/archives")
    end
  end
  def test_filename=()
    check_apt_cache
    @ruby.each {|df|
      d = Debian::Deb.new(IO.readlines("d/w3m_0.2.1-1.f").join(""))
      d.filename = df
      assert_equals(df, d.filename)
    }
  end

  def test_controlFile
    # tested by controlData?
  end
  def test_controlData
    check_apt_cache
    @ruby.each {|df|
      deb = Debian::DpkgDeb.load(df)
      oc = IO.popen("dpkg -f #{df}") {|fp| fp.readlines.join("")}
      assert_equals(oc, deb.controlData)
      om = IO.popen("dpkg -I #{df} md5sums") {|fp| fp.readlines.join("") }
      assert_equals(om, deb.controlData("md5sums"))
    }
  end
  def test_dataFile
    # tested by dataData?
  end
  def test_dataData
    check_apt_cache
    @ruby.each {|df|
      deb = Debian::DpkgDeb.load(df)
      oc = IO.popen("dpkg --fsys-tarfile #{df}|tar xfO - '*/copyright'") {|fp|
	fp.readlines.join("")
      }
      assert_equals(oc, deb.dataData('copyright'))
    }
  end
  def test_sys_tarfile
    check_apt_cache
    @ruby.each {|df|
      deb = Debian::DpkgDeb.load(df)
      os = IO.popen("dpkg --fsys-tarfile #{df}") {|fp|
	fp.readlines.join("")
      }
      ts = deb.sys_tarfile {|fp| fp.readlines.join("") }
      assert_equals(os, ts)
    }
  end

#  def test_s_new
#    
#  end

end
