require_relative 'helper'

class TArchives < Debian::Archives
  def initialize(f = "")
    @file = []
    @lists = {}
    if f != ""
      @file.push(f)
      @lists = Debian::Archives.parseArchiveFile(f) {|info|
        Debian::Deb.new(info)
      }
    end
  end
end

class TestDebian__Archives < MiniTest::Test

  def setup
    @data_dir = File.dirname(__FILE__) + '/../t/d'
    @ar = [TArchives.new("#{@data_dir}/status"),
      TArchives.new("#{@data_dir}/available"),
      TArchives.new("#{@data_dir}/sid_i386_Packages"),
      TArchives.new("#{@data_dir}/non-US_sid_i386_Packages")]
  end
  def test_AND # '&'
    ar = @ar[0] & @ar[1]
    assert_equal('dpkg-ruby', ar['dpkg-ruby'].package)
    assert_nil(ar['smtpfeed'])
    assert_nil(@ar[0]['smtpfeed'])
    assert_equal('smtpfeed', @ar[1]['smtpfeed'].package)
  end

  def test_AREF # '[]'
    assert_equal("dpkg-ruby", @ar[0]['dpkg-ruby'].package)
    assert_equal("auto-apt", @ar[1]['auto-apt'].package)
    assert_equal("hotplug", @ar[2]['hotplug'].package)
    assert_equal("w3mmee-ssl", @ar[3]['w3mmee-ssl'].package)
  end

  def test_ASET # '[]='
    deb = Debian::Deb.new(IO.readlines("#{@data_dir}/w3m_0.2.1-2.f").join(""))
    @ar[3]['w3m'] = deb
    assert_equal(deb, @ar[3]['w3m'])
  end

  def test_LSHIFT # '<<'
    deb = Debian::Deb.new(IO.readlines("#{@data_dir}/w3m_0.2.1-2.f").join(""))
    ar = @ar[3] << deb
    assert_equal(deb, ar['w3m'])
    assert_nil(@ar[3]['w3m'])
    ar = @ar[3] << nil
    assert_nil(ar['w3m'])
    deb = Debian::Deb.new(IO.readlines("#{@data_dir}/w3m_0.2.1-1.f").join(""))
    ar = @ar[0] << deb
    assert_equal('0.2.1-2', ar['w3m'].version)
  end

  def test_MINUS # '-'
    ar = @ar[1] - @ar[0]
    assert_nil(ar['dpkg-ruby'])
    assert_equal('dpkg-ruby', @ar[1]['dpkg-ruby'].package)
    assert_equal('dpkg-ruby', @ar[0]['dpkg-ruby'].package)
    assert_equal('smtpfeed', ar['smtpfeed'].package)
  end

  def test_PLUS # '+'
    ar = @ar[2] + @ar[3]
    assert_equal('w3mmee-ssl', ar['w3mmee-ssl'].package)
    assert_nil(@ar[2]['w3mmee-ssl'])
  end

  def test_RSHIFT # '>>'
    deb = Debian::Deb.new(IO.readlines("#{@data_dir}/w3m_0.2.1-2.f").join(""))
    ar = @ar[0] >> deb
    assert_nil(ar['w3m'])
    assert_equal('w3m', @ar[0]['w3m'].package)
    deb = Debian::Deb.new(IO.readlines("#{@data_dir}/w3m_0.2.1-1.f").join(""))
    ar = @ar[0] >> deb
    assert_equal('w3m', ar['w3m'].package)
    ar = @ar[0] >> nil
    assert_equal('w3m', ar['w3m'].package)
  end

  def test_add
    @ar[2].add(@ar[3])
    assert_equal('w3mmee-ssl', @ar[2]['w3mmee-ssl'].package)
  end

  def test_delete
    @ar[0].delete('w3m')
    assert_nil(@ar[0]['w3m'])
  end

  def test_delete_if
    deb = Debian::Deb.new(IO.readlines("#{@data_dir}/w3m_0.2.1-1.f").join(""))
    @ar[0].delete_if {|p,d| d == deb }
    assert_equal('w3m', @ar[0]['w3m'].package)
    deb = Debian::Deb.new(IO.readlines("#{@data_dir}/w3m_0.2.1-2.f").join(""))
    @ar[0].delete_if {|p,d| d == deb }
    assert_nil(@ar[0]['w3m'])
  end

  def test_each
    ps = ['w3mmee-ssl', 'w3m-ssl']
    @ar[3].each {|p, d| ps.delete(p)}
    assert(ps.empty?)
  end

  def test_each_key
    ps = ['w3mmee-ssl', 'w3m-ssl']
    @ar[3].each_key {|p| ps.delete(p)}
    assert(ps.empty?)
  end

  def test_each_package
    ds = [Debian::Deb.new(IO.readlines("#{@data_dir}/w3m-ssl_0.2.1-2.f").join(""))]
    @ar[3].each_package {|d| ds.delete(d)}
    assert(ds.empty?)
  end

  def test_each_value
    ds = [Debian::Deb.new(IO.readlines("#{@data_dir}/w3m-ssl_0.2.1-2.f").join(""))]
    @ar[3].each_package {|d| ds.delete(d)}
    assert(ds.empty?)
  end

  def test_empty?
    assert(!@ar[0].empty?)
    ar = @ar[0] - @ar[0]
    assert(ar.empty?)
  end

  def test_file
    assert_equal(["#{@data_dir}/status"], @ar[0].file)
    assert_equal(["#{@data_dir}/available"], @ar[1].file)
    assert_equal(["#{@data_dir}/sid_i386_Packages"], @ar[2].file)
    assert_equal(["#{@data_dir}/non-US_sid_i386_Packages"], @ar[3].file)
    assert_equal(["#{@data_dir}/status", "#{@data_dir}/available"], (@ar[0] + @ar[1]).file)
  end

  def test_has_key?
    assert(@ar[0].has_key?('dpkg-ruby'))
    assert(@ar[1].has_key?('auto-apt'))
    assert(@ar[2].has_key?('hotplug'))
    assert(@ar[3].has_key?('w3mmee-ssl'))
  end

  def test_has_value?
    deb = Debian::Deb.new(IO.readlines("#{@data_dir}/w3m-ssl_0.2.1-2.f").join(""))
    assert(!@ar[2].has_value?(deb))
    assert(@ar[3].has_value?(deb))
    deb = Debian::Deb.new(IO.readlines("#{@data_dir}/w3m-ssl_0.2.1-1.f").join(""))
    assert(!(@ar[3].has_value?(deb)))
  end

  def test_include?
    assert(@ar[0].include?('dpkg-ruby'))
    assert(@ar[1].include?('auto-apt'))
    assert(@ar[2].include?('hotplug'))
    assert(@ar[3].include?('w3mmee-ssl'))
  end

  def test_indexes
    deb = Debian::Deb.new(IO.readlines("#{@data_dir}/w3m-ssl_0.2.1-2.f").join(""))
    assert_equal([deb], @ar[3].indexes('w3m-ssl'))
  end

  def test_indices
    deb = Debian::Deb.new(IO.readlines("#{@data_dir}/w3m-ssl_0.2.1-2.f").join(""))
    assert_equal([deb], @ar[3].indexes('w3m-ssl'))
  end

  def test_intersect
    ar = @ar[0].class.new
    ar.intersect(@ar[0], @ar[1])
    assert_equal('dpkg-ruby', ar['dpkg-ruby'].package)
    assert_nil(ar['smtpfeed'])
    assert_equal('smtpfeed', @ar[1]['smtpfeed'].package)
  end

  def test_key?
    assert(@ar[0].key?('dpkg-ruby'))
    assert(@ar[1].key?('auto-apt'))
    assert(@ar[2].key?('hotplug'))
    assert(@ar[3].key?('w3mmee-ssl'))
  end

  def test_keys
    ps = ['w3m-ssl', 'w3mmee-ssl'].sort
    assert_equal(ps, @ar[3].keys.sort)
  end

  def test_length
    assert_equal(18, @ar[0].length)
    assert_equal(24, @ar[1].length)
    assert_equal(21, @ar[2].length)
    assert_equal(2, @ar[3].length)
  end

  def test_lists
    assert_equal(['w3m-ssl', 'w3mmee-ssl'].sort, @ar[3].lists.keys.sort)
  end

  def test_package
    deb = Debian::Deb.new(IO.readlines("#{@data_dir}/w3m-ssl_0.2.1-2.f").join(""))
    assert_nil(@ar[3].package('w3m'))
    assert_equal(deb, @ar[3].package('w3m-ssl'))
  end

  def test_pkgnames
    assert_equal(['w3m-ssl', 'w3mmee-ssl'].sort, @ar[3].pkgnames.sort)
  end

  def test_store
    deb = Debian::Deb.new(IO.readlines("#{@data_dir}/w3m_0.2.1-2.f").join(""))
    @ar[3].store('w3m', deb)
    assert_equal(deb, @ar[3]['w3m'])
  end

  def test_sub
    @ar[1].sub(@ar[0])
    assert_nil(@ar[1]['dpkg-ruby'])
    assert_equal('dpkg-ruby', @ar[0]['dpkg-ruby'].package)
    assert_equal('smtpfeed', @ar[1]['smtpfeed'].package)
  end

  def test_to_s
    assert_equal("#{@data_dir}/status", @ar[0].to_s)
    assert_equal("#{@data_dir}/available", @ar[1].to_s)
    assert_equal("#{@data_dir}/sid_i386_Packages", @ar[2].to_s)
    assert_equal("#{@data_dir}/non-US_sid_i386_Packages", @ar[3].to_s)
    assert_equal("#{@data_dir}/status+#{@data_dir}/available", (@ar[0]+@ar[1]).to_s)
  end

  def test_value?
    deb = Debian::Deb.new(IO.readlines("#{@data_dir}/w3m-ssl_0.2.1-2.f").join(""))
    assert(!@ar[2].has_value?(deb))
    assert(@ar[3].has_value?(deb))
    deb = Debian::Deb.new(IO.readlines("#{@data_dir}/w3m-ssl_0.2.1-1.f").join(""))
    assert(!(@ar[3].has_value?(deb)))
  end

  def test_values
    ds = [Debian::Deb.new(IO.readlines("#{@data_dir}/w3m-ssl_0.2.1-2.f").join(""))]
    @ar[3].values.each {|d| ds.delete(d)}
    assert(ds.empty?)
  end

#  def test_s_parse
#    
#  end

#  def test_s_parseAptLine
#    
#  end

#  def test_s_parseArchiveFile
#    
#  end

end
