require_relative 'helper'

class TestDebian__Dsc < MiniTest::Test

  def setup
    @data_dir = File.dirname(__FILE__) + '/../t/d'
    @dsc = [Debian::Dsc.new(IO.readlines("#{@data_dir}/w3m_0.2.1-1.dsc").join("")),
            Debian::Dsc.new(IO.readlines("#{@data_dir}/w3m_0.2.1-2.dsc").join("")),
            Debian::Dsc.new(IO.readlines("#{@data_dir}/w3m-ssl_0.2.1-2.dsc").join(""))]
  end

  def test_binary
    assert_equals(["w3m"], @dsc[0].binary)
    assert_equals(["w3m"], @dsc[1].binary)
    assert_equals(["w3m-ssl"], @dsc[2].binary)
  end

  def test_package
    assert_equals("w3m", @dsc[0].package)
    assert_equals("w3m", @dsc[1].package)
    assert_equals("w3m-ssl", @dsc[2].package)
  end

  def test_version
    assert_equals("0.2.1-1", @dsc[0].version)
    assert_equals("0.2.1-2", @dsc[1].version)
    assert_equals("0.2.1-2", @dsc[2].version)
  end

#  def test_s_new
#    
#  end

end

if $0 == __FILE__
  if ARGV.size == 0
    suite = TestDebian__Dsc.suite
  else
    suite = RUNIT::TestSuite.new
    ARGV.each do |testmethod|
      suite.add_test(TestDebian__Dsc.new(testmethod))
    end
  end
  RUNIT::CUI::TestRunner.run(suite)
end
