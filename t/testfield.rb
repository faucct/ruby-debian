require_relative 'helper'

class ClassDebianField
  include Debian::Field
  def initialize(c, rf=[])
    parseFields(c, rf)
  end
end

class TestDebian__Field < MiniTest::Test

  def setup
    @ff = {}
    @data_dir = File.dirname(__FILE__) + '/../t/d'
    Dir["#{@data_dir}/*.f"].each {|ff|
      dc = ClassDebianField.new(IO.readlines(ff).join(""), [])
      @ff["#{dc['package']}_#{dc['version']}"] = dc
    }
  end

  def test_AREF # '[]'
    assert_equals("w3m", @ff['w3m_0.2.1-1']['package'])
    assert_equals("w3m-ssl", @ff['w3m-ssl_0.2.1-1']['package'])
    assert_equals("0.2.1-1", @ff['w3m_0.2.1-1']['version'])
  end

  def test_EQUAL # '=='
    dc2 = ClassDebianField.new(IO.readlines("#{@data_dir}/w3m_0.2.1-1.f").join(""), [])
    assert(dc2 == @ff['w3m_0.2.1-1'])
    assert(!(dc2 == @ff['w3m_0.2.1-2']))
    assert(!(dc2 == @ff['w3m-ssl_0.2.1-1']))
  end

  def test_GE # '>='
    assert(@ff['w3m_0.2.1-2'] >= @ff['w3m_0.2.1-1'])
    assert(@ff['w3m_0.2.1-1'] >= @ff['w3m_0.2.1-1'])
    assert(!(@ff['w3m_0.2.1-1'] >= @ff['w3m_0.2.1-2']))
    assert(!(@ff['w3m-ssl_0.2.1-2'] >= @ff['w3m_0.2.1-1']))
    assert(!(@ff['w3m-ssl_0.2.1-1'] >= @ff['w3m_0.2.1-1']))
    assert(!(@ff['w3m-ssl_0.2.1-1'] >= @ff['w3m_0.2.1-2']))
  end

  def test_GT # '>'
    assert(@ff['w3m_0.2.1-2'] > @ff['w3m_0.2.1-1'])
    assert(!(@ff['w3m_0.2.1-1'] > @ff['w3m_0.2.1-1']))
    assert(!(@ff['w3m_0.2.1-1'] > @ff['w3m_0.2.1-2']))
    assert(!(@ff['w3m-ssl_0.2.1-2'] > @ff['w3m_0.2.1-1']))
    assert(!(@ff['w3m-ssl_0.2.1-1'] > @ff['w3m_0.2.1-1']))
    assert(!(@ff['w3m-ssl_0.2.1-1'] > @ff['w3m_0.2.1-2']))
  end

  def test_LE # '<='
    assert(@ff['w3m_0.2.1-1'] <= @ff['w3m_0.2.1-1'])
    assert(@ff['w3m_0.2.1-1'] <= @ff['w3m_0.2.1-2'])
    assert(!(@ff['w3m_0.2.1-2'] <= @ff['w3m_0.2.1-1']))
    assert(!(@ff['w3m-ssl_0.2.1-2'] <= @ff['w3m_0.2.1-1']))
    assert(!(@ff['w3m-ssl_0.2.1-1'] <= @ff['w3m_0.2.1-1']))
    assert(!(@ff['w3m-ssl_0.2.1-1'] <= @ff['w3m_0.2.1-2']))
  end

  def test_LT # '<'
    assert(@ff['w3m_0.2.1-1'] < @ff['w3m_0.2.1-2'])
    assert(!(@ff['w3m_0.2.1-1'] < @ff['w3m_0.2.1-1']))
    assert(!(@ff['w3m_0.2.1-2'] < @ff['w3m_0.2.1-1']))
    assert(!(@ff['w3m-ssl_0.2.1-2'] > @ff['w3m_0.2.1-1']))
    assert(!(@ff['w3m-ssl_0.2.1-1'] > @ff['w3m_0.2.1-1']))
    assert(!(@ff['w3m-ssl_0.2.1-1'] > @ff['w3m_0.2.1-2']))
  end

  def test_VERY_EQUAL # '==='
    assert(@ff['w3m_0.2.1-1'] === @ff['w3m_0.2.1-1'])
    assert(@ff['w3m_0.2.1-1'] === @ff['w3m_0.2.1-2'])
    assert(@ff['w3m_0.2.1-2'] === @ff['w3m_0.2.1-1'])
    assert(!(@ff['w3m_0.2.1-1'] === @ff['w3m-ssl_0.2.1-1']))
    assert(!(@ff['w3m_0.2.1-1'] === @ff['w3m-ssl_0.2.1-2']))
  end

  def test_info_s
    c = IO.readlines("#{@data_dir}/w3m_0.2.1-1.f").join("")
    assert_equals(c, @ff['w3m_0.2.1-1'].info_s)
  end

  def test_fields
    assert_equals(['Package', 'Version', 'Section', 'Priority',
		    'Architecture', 'Depends', 'Suggests',
		    'Provides', 'Installed-size', 'Maintainer',
		    'Description'], @ff['w3m_0.2.1-1'].fields)
  end

  def test_info
    assert_equals({'Package' => 'w3m',
		    'Version' => '0.2.1-1',
		    'Section' => 'text',
		    'Priority' => 'optional',
		    'Architecture' => 'i386',
		    'Depends' => 'libc6 (>= 2.2.1-2), libgc5, libgpmg1 (>= 1.14-16), libncurses5 (>= 5.2.20010310-1)',
		    'Suggests' => 'w3m-ssl (>= 0.2.1-1), mime-support, menu (>> 1.5), w3m-el',
		    'Provides' => 'www-browser',
		    'Installed-size' => '1300',
		    'Maintainer' => 'Fumitoshi UKAI <ukai@debian.or.jp>',
		    'Description' => 'WWW browsable pager with excellent tables/frames support
 w3m is a text-based World Wide Web browser with IPv6 support.
 It features excellent support for tables and frames. It can be used
 as a standalone file pager, too.
 .
  * You can follow links and/or view images in HTML.
  * Internet message prewview mode, you can browse HTML mail.
  * You can follow links in plain text if it includes URL forms.
 .
 For more information,
 see http://ei5nazha.yz.yamagata-u.ac.jp/~aito/w3m/eng/index.html'},
		  @ff['w3m_0.2.1-1'].info)
  end

  def test_package
    assert_equals('w3m', @ff['w3m_0.2.1-1'].package)
    assert_equals('w3m-ssl', @ff['w3m-ssl_0.2.1-2'].package)
  end

  def test_version
    assert_equals('0.2.1-1', @ff['w3m_0.2.1-1'].version)
    assert_equals('0.2.1-2', @ff['w3m-ssl_0.2.1-2'].version)
  end

  def test_maintainer
    assert_equals('Fumitoshi UKAI <ukai@debian.or.jp>', @ff['w3m_0.2.1-1'].maintainer)
  end

#  def test_parseFields
#	how to test?    
#  end

  def test_to_s
    assert_equals("w3m 0.2.1-1", @ff['w3m_0.2.1-1'].to_s)
    assert_equals("w3m 0.2.1-2", @ff['w3m_0.2.1-2'].to_s)
    assert_equals("w3m-ssl 0.2.1-1", @ff['w3m-ssl_0.2.1-1'].to_s)
    assert_equals("w3m-ssl 0.2.1-2", @ff['w3m-ssl_0.2.1-2'].to_s)
  end

end
