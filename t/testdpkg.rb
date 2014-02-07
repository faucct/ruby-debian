# c2t.rb -na Debian::Dpkg ../lib/debian.rb > testdpkg.rb
#
require_relative 'helper'

class TestDebian__Dpkg < MiniTest::Test

  def test_s_architecture
    arch = %x{dpkg --print-architecture}.chomp!
    assert_equal(arch, Debian::Dpkg.architecture())
  end
  def test_s_gnu_build_architecture
    arch = %x{dpkg --print-gnu-build-architecture}.chomp!
    assert_equal(arch, Debian::Dpkg.gnu_build_architecture())
  end

  def test_s_installation_architecture
    arch = %x{dpkg --print-installation-architecture}.chomp!
    assert_equal(arch, Debian::Dpkg.installation_architecture())
  end

  def test_s_compare_versions
    assert(Debian::Dpkg.compare_versions('1.0','<','1.1'))
    assert(Debian::Dpkg.compare_versions('1.0','<=','1.1'))
    assert(Debian::Dpkg.compare_versions('1.0','<=','1.0'))
    assert(Debian::Dpkg.compare_versions('1.0','=','1.0'))
    assert(Debian::Dpkg.compare_versions('1.0','>=','1.0'))
    assert(Debian::Dpkg.compare_versions('1.1','>','1.0'))
  end

  def test_s_field
    ruby = Dir["/var/cache/apt/archives/ruby2.0_*.deb"]
    if ruby.empty?
      flunk("no ruby package in /var/cache/apt/archives")
    end
    ruby.each {|deb|
      d = Debian::Dpkg.field(deb)
      assert_equal("ruby", d.package)
      assert_matches(d.version, /1.6/)
      assert_equal("akira yamada <akira@debian.org>", d['maintainer'])
      assert_equal("interpreters", d['section'])
      assert_equal("optional", d['priority'])
      # request field only
      assert_equal(["ruby"], Debian::Dpkg.field(deb, ["package"]))
      assert_equal(["akira yamada <akira@debian.org>"], 
		    Debian::Dpkg.field(deb, ["maintainer"]))
      assert_equal(["interpreters"], Debian::Dpkg.field(deb, ["section"]))
      assert_equal(["optional"], Debian::Dpkg.field(deb, ["priority"]))
      assert_equal(["ruby","interpreters","optional"],
		    Debian::Dpkg.field(deb, ["package","section","priority"]))
    }
  end

  LIST_SELECTION = Debian::Deb::SELECTION_ID.invert
  LIST_STATUS = Debian::Deb::STATUS_ID.invert
  
  def dpkg_l_parse(line)
    if /^(.)(.)(.)\s+(\S+)\s+(\S+)\s+(.*)/ =~ line
      {'selection' => $1,
	'status' => $2,
	'err?' => $3,
	'package' => $4,
	'version' => $5,
	'description' => $6
      }
    else
      flunk("parse failed dpkg -l #{line}")
    end
  end
  def test_s_status
    dpkg_l = ''
    ENV['COLUMNS']="256"
    IO.popen("dpkg --list dpkg") {|f|
      f.each {|line|
	break if /^\+/ =~ line
      }
      dpkg_l = dpkg_l_parse(f.readlines[0])
    }
    dpkg_tl = Debian::Dpkg.status(['dpkg'])
    assert_not_nil(dpkg_tl['dpkg'])
    assert_equal('dpkg', dpkg_tl['dpkg'].package)
    assert_equal(LIST_SELECTION[dpkg_l['selection']], 
		  dpkg_tl['dpkg'].selection)
    assert_equal(LIST_STATUS[dpkg_l['status']], 
		  dpkg_tl['dpkg'].status)
    assert_equal(dpkg_l['version'], 
		  dpkg_tl['dpkg'].version.slice(0,dpkg_l['version'].length))
    assert_equal('Package maintenance system for Debian',
		  dpkg_tl['dpkg'].description.slice(0,'Package maintenance system for Debian'.length))

    ol = {}
    IO.popen("dpkg --list") {|f|
      f.each {|line|
	break if /^\+/ =~ line

      }
      f.each {|line|
	l = dpkg_l_parse(line)
	next if ol.include?(l['package'])
	ol[l['package']] = l
      }
    }
    tl = Debian::Dpkg.status
    ol.each {|op,ol|
      tp = nil
      dupped = false
      tl.each_key {|t|
	if t == op
	  tp = tl[t]
	  break
	end
	if t.slice(0,14) == op
	  if tp
	    dupped = true
	    break
	  end
	  tp = tl[t]
	end
      }
      next if dupped
      assert_not_nil(tp, "#{op}")
      assert_equal(op, tp.package.slice(0,op.length),
		    "#{op}/#{tp.package}")
      assert_equal(ol['package'], tp.package.slice(0,ol['package'].length),
		    "#{ol['pacakge']}/#{tp.package}")
      assert_equal(LIST_SELECTION[ol['selection']], tp.selection, tp.package)
      assert_equal(LIST_STATUS[ol['status']], tp.status, tp.package)
      assert_equal(ol['version'], tp.version.gsub(/^\d+:/,"").slice(0,ol['version'].length), tp.package)
      assert_equal(ol['description'], tp.description.slice(0,ol['description'].length), tp.package)
    }
  end

  def test_s_selections
    # dpkg --get-selections ...
    sl = {}
    IO.popen("dpkg --get-selections") {|f|
      f.each {|line|
	p,sel = line.split
	sl[p] = sel
      }
    }
    tsl = Debian::Dpkg.selections
    sl.each {|p,sel|
      assert_equal(sel, tsl[p].selection)
    }
  end
#  def test_s_selections=
#    # dpkg --set-selections
#  end
  def test_s_avail
    # dpkg --print-avail ...
    a = IO.popen("dpkg --print-avail w3m") {|f|
      Debian::Deb.new(f.readlines.join(""))
    }
    ta = Debian::Dpkg.avail(['w3m'])
    assert_equal(a, ta['w3m'])
  end
  def test_s_listfiles
    # dpkg --listfiles ...
    l = IO.popen("dpkg --listfiles dpkg gzip").readlines("\n\n").collect {|l| 
      l.split("\n")
    }
    tl = Debian::Dpkg.listfiles(['dpkg', 'gzip'])
    assert_equal(l, tl)
  end
  def test_s_search
    # dpkg --search
    s = IO.popen("dpkg --search dpkg-deb").readlines.collect {|l|
      l.chomp!
      /^(\S+):\s*(\S+)/ =~ l
      [$1, $2]
    }.sort {|a,b| (a[0] + a[1]) <=> (b[0] + b[1]) }
    ts = Debian::Dpkg.search(['dpkg-deb']).sort {|a,b| 
      (a[0] + a[1]) <=> (b[0] + b[1])
    }
    assert_equal(s, ts)
  end
#  def test_s_audit
#    # dpkg --audit
#  end

end
