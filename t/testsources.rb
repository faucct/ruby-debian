require_relative 'helper'

class TestDebian__Sources < MiniTest::Test
  

  def setup
    @ss = [Debian::Sources.new("d/sid_Sources"),
           Debian::Sources.new("d/non-US_sid_Sources")]
  end

  def test_s_new
    @ss[0].each {|p,s|  assert_equal(Debian::Dsc, s.class) }
    @ss[1].each {|p,s|  assert_equal(Debian::Dsc, s.class) }
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
