# c2t.rb -na Debian::Dpkg ../lib/debian.rb > testdpkg.rb
#
require 'runit/testcase'
require 'runit/cui/testrunner'

$LOAD_PATH.unshift('../lib')
require '../lib/debian.rb'

class TestDebian__Dpkg < RUNIT::TestCase
  def test_s_architecture
    arch = `dpkg --print-architecture`.chomp!
    assert_equals(arch, Debian::Dpkg.architecture)
  end

  def test_s_gnu_build_architecture
    arch = `dpkg --print-gnu-build-architecture`.chomp!
    assert_equals(arch, Debian::Dpkg.gnu_build_architecture)
  end

  def test_s_installation_architecture
    arch = `dpkg --print-installation-architecture`.chomp!
    assert_equals(arch, Debian::Dpkg.installation_architecture)
  end

  def test_s_compare_versions
    assert(Debian::Dpkg.compare_versions('1.0', '<', '1.1'))
    assert(Debian::Dpkg.compare_versions('1.0', '<=', '1.1'))
    assert(Debian::Dpkg.compare_versions('1.0', '<=', '1.0'))
    assert(Debian::Dpkg.compare_versions('1.0', '=', '1.0'))
    assert(Debian::Dpkg.compare_versions('1.0', '>=', '1.0'))
    assert(Debian::Dpkg.compare_versions('1.1', '>', '1.0'))
  end

  def test_s_field
    ruby = Dir['/var/cache/apt/archives/ruby_1.6*.deb']
    assert_fail('no ruby package in /var/cache/apt/archives') if ruby.empty?
    ruby.each do |deb|
      d = Debian::Dpkg.field(deb)
      assert_equals('ruby', d.package)
      assert_matches(d.version, /1.6/)
      assert_equals('akira yamada <akira@debian.org>', d['maintainer'])
      assert_equals('interpreters', d['section'])
      assert_equals('optional', d['priority'])
      # request field only
      assert_equals(['ruby'], Debian::Dpkg.field(deb, ['package']))
      assert_equals(['akira yamada <akira@debian.org>'],
                    Debian::Dpkg.field(deb, ['maintainer']))
      assert_equals(['interpreters'], Debian::Dpkg.field(deb, ['section']))
      assert_equals(['optional'], Debian::Dpkg.field(deb, ['priority']))
      assert_equals(%w(ruby interpreters optional),
                    Debian::Dpkg.field(deb, %w(package section priority)))
    end
  end

  LIST_SELECTION = Debian::Deb::SELECTION_ID.invert
  LIST_STATUS = Debian::Deb::STATUS_ID.invert

  def dpkg_l_parse(line)
    if /^(.)(.)(.)\s+(\S+)\s+(\S+)\s+(.*)/ =~ line
      { 'selection' => Regexp.last_match(1),
        'status' => Regexp.last_match(2),
        'err?' => Regexp.last_match(3),
        'package' => Regexp.last_match(4),
        'version' => Regexp.last_match(5),
        'description' => Regexp.last_match(6) }
    else
      assert_fail("parse failed dpkg -l #{line}")
    end
  end

  def test_s_status
    dpkg_l = ''
    ENV['COLUMNS'] = '256'
    IO.popen('dpkg --list dpkg') do |f|
      f.each do |line|
        break if /^\+/ =~ line
      end
      dpkg_l = dpkg_l_parse(f.readlines[0])
    end
    dpkg_tl = Debian::Dpkg.status(['dpkg'])
    assert_not_nil(dpkg_tl['dpkg'])
    assert_equals('dpkg', dpkg_tl['dpkg'].package)
    assert_equals(LIST_SELECTION[dpkg_l['selection']],
                  dpkg_tl['dpkg'].selection)
    assert_equals(LIST_STATUS[dpkg_l['status']],
                  dpkg_tl['dpkg'].status)
    assert_equals(dpkg_l['version'],
                  dpkg_tl['dpkg'].version.slice(0, dpkg_l['version'].length))
    assert_equals('Package maintenance system for Debian',
                  dpkg_tl['dpkg'].description.slice(0, 'Package maintenance system for Debian'.length))

    ol = {}
    IO.popen('dpkg --list') do |f|
      f.each do |line|
        break if /^\+/ =~ line
      end
      f.each do |line|
        l = dpkg_l_parse(line)
        next if ol.include?(l['package'])
        ol[l['package']] = l
      end
    end
    tl = Debian::Dpkg.status
    ol.each do |op, ol|
      tp = nil
      dupped = false
      tl.each_key do |t|
        if t == op
          tp = tl[t]
          break
        end
        next unless t.slice(0, 14) == op
        if tp
          dupped = true
          break
        end
        tp = tl[t]
      end
      next if dupped
      assert_not_nil(tp, op.to_s)
      assert_equals(op, tp.package.slice(0, op.length),
                    "#{op}/#{tp.package}")
      assert_equals(ol['package'], tp.package.slice(0, ol['package'].length),
                    "#{ol['pacakge']}/#{tp.package}")
      assert_equals(LIST_SELECTION[ol['selection']], tp.selection, tp.package)
      assert_equals(LIST_STATUS[ol['status']], tp.status, tp.package)
      assert_equals(ol['version'], tp.version.gsub(/^\d+:/, '').slice(0, ol['version'].length), tp.package)
      assert_equals(ol['description'], tp.description.slice(0, ol['description'].length), tp.package)
    end
  end

  def test_s_selections
    # dpkg --get-selections ...
    sl = {}
    IO.popen('dpkg --get-selections') do |f|
      f.each do |line|
        p, sel = line.split
        sl[p] = sel
      end
    end
    tsl = Debian::Dpkg.selections
    sl.each do |p, sel|
      assert_equals(sel, tsl[p].selection)
    end
  end

  #  def test_s_selections=
  #    # dpkg --set-selections
  #  end
  def test_s_avail
    # dpkg --print-avail ...
    a = IO.popen('dpkg --print-avail w3m') do |f|
      Debian::Deb.new(f.readlines.join(''))
    end
    ta = Debian::Dpkg.avail(['w3m'])
    assert_equals(a, ta['w3m'])
  end

  def test_s_listfiles
    # dpkg --listfiles ...
    l = IO.popen('dpkg --listfiles dpkg gzip').readlines("\n\n").collect do |l|
      l.split("\n")
    end
    tl = Debian::Dpkg.listfiles(%w(dpkg gzip))
    assert_equals(l, tl)
  end

  def test_s_search
    # dpkg --search
    s = IO.popen('dpkg --search dpkg-deb').readlines.collect do |l|
      l.chomp!
      /^(\S+):\s*(\S+)/ =~ l
      [Regexp.last_match(1), Regexp.last_match(2)]
    end.sort { |a, b| (a[0] + a[1]) <=> (b[0] + b[1]) }
    ts = Debian::Dpkg.search(['dpkg-deb']).sort do |a, b|
      (a[0] + a[1]) <=> (b[0] + b[1])
    end
    assert_equals(s, ts)
  end
  #  def test_s_audit
  #    # dpkg --audit
  #  end
end

if $PROGRAM_NAME == __FILE__
  if ARGV.empty?
    suite = TestDebian__Dpkg.suite
  else
    suite = RUNIT::TestSuite.new
    ARGV.each do |testmethod|
      suite.add_test(TestDebian__Dpkg.new(testmethod))
    end
  end
  RUNIT::CUI::TestRunner.run(suite)
end
