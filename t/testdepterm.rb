require_relative 'helper'

class TestDebian__Dep__Term < MiniTest::Test

  def setup
    @dep = [Debian::Dep::Term.new('w3m'),
  	    Debian::Dep::Term.new('w3m', '<<', '0.2.1-2'),
  	    Debian::Dep::Term.new('w3m', '<=', '0.2.1-2'),
  	    Debian::Dep::Term.new('w3m', '=', '0.2.1-2'),
  	    Debian::Dep::Term.new('w3m', '>=', '0.2.1-2'),
  	    Debian::Dep::Term.new('w3m', '>>', '0.2.1-2'),
  	    Debian::Dep::Term.new('w3m', '==', '0.2.1-2'),
      	    Debian::Dep::Term.new('www-browser')]
  end
  def test_EQUAL # '=='
    assert_equals(Debian::Dep::Term.new('w3m'), @dep[0])
    assert_equals(Debian::Dep::Term.new('w3m', '<<', '0.2.1-2'), @dep[1])
  end

  def test_op
    assert_equals("", @dep[0].op)
    assert_equals("<<", @dep[1].op)
    assert_equals("<=", @dep[2].op)
    assert_equals("=", @dep[3].op)
    assert_equals(">=", @dep[4].op)
    assert_equals(">>", @dep[5].op)
  end

  def test_package
    assert_equals("w3m", @dep[0].package)
    assert_equals("w3m", @dep[1].package)
  end

  def test_satisfy?
    @deb = [Debian::Deb.new(IO.readlines("d/w3m_0.2.1-1.f").join("")),
      	    Debian::Deb.new(IO.readlines("d/w3m_0.2.1-2.f").join("")),
      	    Debian::Deb.new(IO.readlines("d/w3m-ssl_0.2.1-1.f").join("")),
      	    Debian::Deb.new(IO.readlines("d/w3m-ssl_0.2.1-2.f").join(""))]
    # w3m
    assert(@dep[0].satisfy?(@deb[0]))
    assert(@dep[0].satisfy?(@deb[1]))
    assert(!(@dep[0].satisfy?(@deb[2])))
    assert(!(@dep[0].satisfy?(@deb[3])))

    # w3m << 0.2.1-2
    assert(@dep[1].satisfy?(@deb[0]))
    assert(!(@dep[1].satisfy?(@deb[1])))
    assert(!(@dep[1].satisfy?(@deb[2])))
    assert(!(@dep[1].satisfy?(@deb[3])))

    # w3m <= 0.2.1-2
    assert(@dep[2].satisfy?(@deb[0]))
    assert(@dep[2].satisfy?(@deb[1]))
    assert(!(@dep[2].satisfy?(@deb[2])))
    assert(!(@dep[2].satisfy?(@deb[3])))

    # w3m = 0.2.1-2
    assert(!(@dep[3].satisfy?(@deb[0])))
    assert(@dep[3].satisfy?(@deb[1]))
    assert(!(@dep[3].satisfy?(@deb[2])))
    assert(!(@dep[3].satisfy?(@deb[3])))

    # w3m >= 0.2.1-2
    assert(!(@dep[4].satisfy?(@deb[0])))
    assert(@dep[4].satisfy?(@deb[1]))
    assert(!(@dep[4].satisfy?(@deb[2])))
    assert(!(@dep[4].satisfy?(@deb[3])))

    # w3m >> 0.2.1-2
    assert(!(@dep[5].satisfy?(@deb[0])))
    assert(!(@dep[5].satisfy?(@deb[1])))
    assert(!(@dep[5].satisfy?(@deb[2])))
    assert(!(@dep[5].satisfy?(@deb[3])))

    # w3m == 0.2.1-2
    assert_exception(Debian::DepError) { @dep[6].satisfy?(@deb[0])}
    assert_exception(Debian::DepError) { @dep[6].satisfy?(@deb[1])}
    assert_exception(Debian::DepError) { @dep[6].satisfy?(@deb[2])}
    assert_exception(Debian::DepError) { @dep[6].satisfy?(@deb[3])}

    # www-browser (provides test)
    assert(@dep[7].satisfy?(@deb[0]))
    assert(@dep[7].satisfy?(@deb[1]))
    assert(@dep[7].satisfy?(@deb[2]))
    assert(@dep[7].satisfy?(@deb[3]))
  end

  def test_to_s
    assert_equals("w3m", @dep[0].to_s)
    assert_equals("w3m (<< 0.2.1-2)", @dep[1].to_s)
    assert_equals("w3m (<= 0.2.1-2)", @dep[2].to_s)
    assert_equals("w3m (= 0.2.1-2)", @dep[3].to_s)
    assert_equals("w3m (>= 0.2.1-2)", @dep[4].to_s)
    assert_equals("w3m (>> 0.2.1-2)", @dep[5].to_s)
  end

  def test_unmet
    p = Debian::Packages.new("d/w3m_met_list")
    assert_equals([], @dep[0].unmet(p)) # w3m
    assert_equals([Debian::Dep::Unmet.new(@dep[1], p['w3m'])],
		  @dep[1].unmet(p)) # w3m << 0.2.1-2
    assert_equals([], @dep[2].unmet(p)) # w3m <= 0.2.1-2
    assert_equals([], @dep[3].unmet(p)) # w3m = 0.2.1-2
    assert_equals([], @dep[4].unmet(p)) # w3m >= 0.2.1-2
    assert_equals([Debian::Dep::Unmet.new(@dep[5], p['w3m'])], 
		  @dep[5].unmet(p)) # w3m >> 0.2.1-2
    assert_equals([], @dep[7].unmet(p)) # www-browser
  end

  def test_version
    assert_equals("", @dep[0].version)
    assert_equals("0.2.1-2", @dep[1].version)
    assert_equals("0.2.1-2", @dep[2].version)
    assert_equals("0.2.1-2", @dep[3].version)
    assert_equals("0.2.1-2", @dep[4].version)
    assert_equals("0.2.1-2", @dep[5].version)
    assert_equals("0.2.1-2", @dep[6].version)
  end

#  def test_s_new
#    
#  end

end

if $0 == __FILE__
  if ARGV.size == 0
    suite = TestDebian__Dep__Term.suite
  else
    suite = RUNIT::TestSuite.new
    ARGV.each do |testmethod|
      suite.add_test(TestDebian__Dep__Term.new(testmethod))
    end
  end
  RUNIT::CUI::TestRunner.run(suite)
end
