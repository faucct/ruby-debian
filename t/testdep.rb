require_relative 'helper'

class TestDebian__Dep < MiniTest::Test

  def setup
    @data_dir = File.dirname(__FILE__) + '/../t/d'
    @dep = [Debian::Dep.new("w3m", 'Depends'),
      	    Debian::Dep.new("w3m | w3m-ssl", 'Depends'),
            Debian::Dep.new("w3m (>= 0.2.1-2) | w3m-ssl (>= 0.2.1-2)", 
			    'Recommends'),
      	    Debian::Dep.new("www-browser", "Suggests")]
  end

  def test_satisfy?
    deb = [Debian::Deb.new(IO.readlines("#{@data_dir}/w3m_0.2.1-1.f").join("")),
           Debian::Deb.new(IO.readlines("#{@data_dir}/w3m_0.2.1-2.f").join("")),
      	   Debian::Deb.new(IO.readlines("#{@data_dir}/w3m-ssl_0.2.1-1.f").join("")),
      	   Debian::Deb.new(IO.readlines("#{@data_dir}/w3m-ssl_0.2.1-2.f").join(""))]
    assert(@dep[0].satisfy?(deb[0]))
    assert(@dep[0].satisfy?(deb[1]))
    assert(!(@dep[0].satisfy?(deb[2])))
    assert(!(@dep[0].satisfy?(deb[3])))

    assert(@dep[1].satisfy?(deb[0]))
    assert(@dep[1].satisfy?(deb[1]))
    assert(@dep[1].satisfy?(deb[2]))
    assert(@dep[1].satisfy?(deb[3]))

    assert(!(@dep[2].satisfy?(deb[0])))
    assert(@dep[2].satisfy?(deb[1]))
    assert(!(@dep[2].satisfy?(deb[2])))
    assert(@dep[2].satisfy?(deb[3]))
  end

  def test_to_s
    assert_equals("Depends w3m", @dep[0].to_s)
    assert_equals("Depends w3m | w3m-ssl", @dep[1].to_s)
    assert_equals("Recommends w3m (>= 0.2.1-2) | w3m-ssl (>= 0.2.1-2)",
		  @dep[2].to_s)
  end

  def test_unmet
    p = Debian::Packages.new("#{@data_dir}/w3m_met_list")
    assert_equals([], @dep[0].unmet(p)) # w3m
    assert_equals([], @dep[1].unmet(p)) # w3m | w3m-ssl
    assert_equals([], @dep[2].unmet(p)) 
    			# w3m (>= 0.2.1-2) | w3m-ssl (>= 0.2.1-2)
    assert_equals([], @dep[3].unmet(p)) # www-browser
  end

#  def test_s_new
#    
#  end

end

if $0 == __FILE__
  if ARGV.size == 0
    suite = TestDebian__Dep.suite
  else
    suite = RUNIT::TestSuite.new
    ARGV.each do |testmethod|
      suite.add_test(TestDebian__Dep.new(testmethod))
    end
  end
  RUNIT::CUI::TestRunner.run(suite)
end
