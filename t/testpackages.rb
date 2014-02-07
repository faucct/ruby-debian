require_relative 'helper'

class TestDebian__Packages < MiniTest::Test

  def setup
    @data_dir = File.dirname(__FILE__) + '/../t/d'
    @ps = [Debian::Packages.new("#{@data_dir}/status"),
      Debian::Packages.new("#{@data_dir}/available"),
      Debian::Packages.new("#{@data_dir}/sid_i386_Packages"),
      Debian::Packages.new("#{@data_dir}/non-US_sid_i386_Packages")]
  end
  def test_AND # '&'
    ps = @ps[0] & @ps[3]
    assert_equal('w3mmee-ssl', ps['w3mmee-ssl'].package)
    assert_nil(ps['dpkg-ruby'])
    assert_equal('dpkg-ruby', @ps[0]['dpkg-ruby'].package)
    assert_nil(@ps[3]['dpkg-ruby'])
    assert_equal(@ps[3].provides.keys.sort, ps.provides.keys.sort)
  end

  def test_ASET # '[]='
    deb = Debian::Deb.new(IO.readlines("#{@data_dir}/w3m_0.2.1-2.f").join(""))
    pr = @ps[3].provides('www-browser').collect {|d| d.package }
    @ps[3]['w3m'] = deb
    assert_equal(deb, @ps[3]['w3m'])
    assert_equal((pr + ['w3m']).sort,
		  @ps[3].provides('www-browser').collect {|d| d.package }.sort)
  end

  def test_LSHIFT # '<<'
    deb = Debian::Deb.new(IO.readlines("#{@data_dir}/w3m_0.2.1-2.f").join(""))
    pr = @ps[3].provides('www-browser').collect {|d| d.package }
    assert_nil(@ps[3]['w3m'])
    ps = @ps[3] << nil
    assert_nil(@ps[3]['w3m'])
    ps = @ps[3] << deb
    assert_nil(@ps[3]['w3m'])
    assert_equal(deb, ps['w3m'])
    assert_equal((pr + ['w3m']).sort,
		  ps.provides('www-browser').collect {|d| d.package }.sort)

  end

  def test_MINUS # '-'
    ps = @ps[1] - @ps[0]
    assert_equal('dpkg-ruby', @ps[1]['dpkg-ruby'].package)
    assert_equal(['donkey', 'fml', 'hex', 'sendmail-wide', 'smtpfeed', 
		    'xfonts-marumoji'],
		  ps.pkgnames.sort)
  end

  def test_PLUS # '+'
    ps = @ps[1] + @ps[0]
    ps.each {|pkg, deb|
      assert_equal(deb, @ps[1][pkg])
    }
    assert_equal(ps.provides.keys.sort, @ps[1].provides.keys.sort)
  end

  def test_RSHIFT # '>>'
    deb = Debian::Deb.new(IO.readlines("#{@data_dir}/w3m_0.2.1-2.f").join(""))
    pr = @ps[0].provides('www-browser').collect {|d| d.package }
    assert_equal('w3m', @ps[0]['w3m'].package)
    ps = @ps[0] >> nil
    assert_equal('w3m', ps['w3m'].package)
    ps = @ps[0] >> deb
    assert_equal('w3m', @ps[0]['w3m'].package)
    assert_nil(ps['w3m'])
    assert_equal((pr - ['w3m']).sort, 
		  ps.provides('www-browser').collect {|d| d.package}.sort)
    
  end

  def test_add
    @ps[0].add(@ps[1])
    assert_equal('donkey', @ps[0]['donkey'].package)
  end

  def test_delete
    @ps[3].delete('w3mmee-ssl')
    assert_nil(@ps[3]['w3mmee-ssl'])
    @ps[3].delete('w3m-ssl')
    assert_nil(@ps[3]['w3mmee-ssl'])
    assert_equal([], @ps[3].provides('www-browser'))
  end

  def test_intersect
    p = Debian::Packages.new
    p.intersect(@ps[0], @ps[3])
    assert_equal('w3m-ssl', p['w3m-ssl'].package)
    assert_equal('w3mmee-ssl', p['w3mmee-ssl'].package)
    assert_nil(p['w3m'])
  end

  def test_provides
    assert_equal(['w3m-ssl', 'w3mmee-ssl'],
		  @ps[3].provides('www-browser').collect {|d| d.package }.sort)
  end

  def test_sub
    @ps[1].sub(@ps[0])
    assert_equal(['donkey', 'fml', 'hex', 'sendmail-wide', 'smtpfeed', 
		    'xfonts-marumoji'],
		  @ps[1].pkgnames.sort)
  end

#  def test_s_new
#    assert_fail("untested")
#  end
#
#  def test_s_parse
#    assert_fail("untested")
#  end
#
#  def test_s_parseAptLine
#    assert_fail("untested")
#  end

#  def test_s_parseArchiveFile
#    assert_fail("untested")
#  end

end
