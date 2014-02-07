require_relative 'helper'

class TestDebian__Status < MiniTest::Test
  
   def test_s_new
     s = Debian::Status.new
     assert((s['dpkg'].data.find {|f| f == "/usr/bin/dpkg" }) != nil)
   end
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
