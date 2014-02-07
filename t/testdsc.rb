require_relative 'helper'

class TestDebian__Dsc < MiniTest::Test

  def setup
    @data_dir = File.dirname(__FILE__) + '/../t/d'
    @dsc = [Debian::Dsc.new(IO.readlines("#{@data_dir}/w3m_0.2.1-1.dsc").join("")),
            Debian::Dsc.new(IO.readlines("#{@data_dir}/w3m_0.2.1-2.dsc").join("")),
            Debian::Dsc.new(IO.readlines("#{@data_dir}/w3m-ssl_0.2.1-2.dsc").join(""))]
  end

  def test_binary
    assert_equal(["w3m"], @dsc[0].binary)
    assert_equal(["w3m"], @dsc[1].binary)
    assert_equal(["w3m-ssl"], @dsc[2].binary)
  end

  def test_package
    assert_equal("w3m", @dsc[0].package)
    assert_equal("w3m", @dsc[1].package)
    assert_equal("w3m-ssl", @dsc[2].package)
  end

  def test_version
    assert_equal("0.2.1-1", @dsc[0].version)
    assert_equal("0.2.1-2", @dsc[1].version)
    assert_equal("0.2.1-2", @dsc[2].version)
  end

#  def test_s_new
#    
#  end

end
