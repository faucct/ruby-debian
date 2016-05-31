require 'runit/testcase'
require 'runit/cui/testrunner'

$LOAD_PATH.unshift('../lib')
require '../lib/debian.rb'

class TestDebian__DpkgDeb < RUNIT::TestCase
  def setup
    @ruby = Dir['/var/cache/apt/archives/ruby_1.6*.deb']
    assert_fail('no ruby package in /var/cache/apt/archives') if @ruby.empty?
    @libs = Dir['/usr/lib/libc.*']
    assert_fail('no libc in /usr/lib') if @libs.empty?
  end

  def test_deb?
    @ruby.each do |deb|
      assert(Debian::DpkgDeb.deb?(deb))
    end
    @libs.each do |lib|
      assert(!Debian::DpkgDeb.deb?(lib))
    end
  end

  def test_assert_deb?
    @ruby.each do |deb|
      assert_no_exception(Debian::Error) { Debian::DpkgDeb.assert_deb?(deb) }
    end
    @libs.each do |lib|
      assert_exception(Debian::Error) { !Debian::DpkgDeb.assert_deb?(lib) }
    end
  end

  def test_control
    ENV['LANG'] = 'C'
    @ruby.each do |deb|
      c = []
      IO.popen("dpkg -I #{deb}") do |fp|
        fp.each do |line|
          line.chomp!
          c.push(Regexp.last_match(1)) if /^\s+\d+\sbytes,\s+\d+\s+lines\s+\*?\s*(\S+).*/ =~ line
        end
      end
      assert_equals(c.sort, Debian::DpkgDeb.control(deb).sort)
    end
  end

  def test_data
    @ruby.each do |deb|
      d = []
      IO.popen("dpkg --fsys-tarfile #{deb}|tar tf -") do |fp|
        fp.each do |line|
          line.chomp!
          d.push(line)
        end
      end
      assert_equals(d, Debian::DpkgDeb.data(deb))
    end
  end

  def test_load
    @ruby.each do |deb|
      de = Debian::DpkgDeb.load(deb)
      assert_equals(deb, de.filename)
    end
  end
end

if $PROGRAM_NAME == __FILE__
  if ARGV.empty?
    suite = TestDebian__DpkgDeb.suite
  else
    suite = RUNIT::TestSuite.new
    ARGV.each do |testmethod|
      suite.add_test(TestDebian__DpkgDeb.new(testmethod))
    end
  end
  RUNIT::CUI::TestRunner.run(suite)
end
