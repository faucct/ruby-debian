require_relative 'helper'

class TestDebian__Dep__Unmet < MiniTest::Test

  def setup
    @data_dir = File.dirname(__FILE__) + '/../t/d'
    dep = Debian::Dep::Term.new('w3m')
    assert_instance_of Debian::Dep::Term, dep
    deb = Debian::Deb.new(IO.readlines("#{@data_dir}/w3m-ssl_0.2.1-1.f").join(""))
    assert_instance_of Debian::Dep::Term, dep
    @unmet = Debian::Dep::Unmet.new(dep, deb)
  end
  def test_deb
    deb = Debian::Deb.new(IO.readlines("#{@data_dir}/w3m-ssl_0.2.1-1.f").join(""))
    assert_equal(deb, @unmet.deb)
  end

  def test_dep
    assert_equal(Debian::Dep::Term.new('w3m'), @unmet.dep)
  end

  def test_package
    assert_nil(@unmet.package)
  end

  def test_package=
    @unmet.package = 'w3m-el'
    assert_equal('w3m-el', @unmet.package)
    assert_exception(Debian::DepError) { @unmet.package = 'w3m' }
  end

  def test_relation
    assert_nil(@unmet.relation)
  end
  
  def test_relation=
    @unmet.relation = 'depends'
    assert_equal('depends', @unmet.relation)
    assert_exception(Debian::DepError) { @unmet.relation = 'recommends' }
  end

  def test_to_s
    assert_equal('w3m unmet w3m-ssl 0.2.1-1 (provides w3m)', @unmet.to_s)
    @unmet.package = 'w3m-ssl'
    assert_equal('w3m-ssl w3m unmet w3m-ssl 0.2.1-1 (provides w3m)', 
		  @unmet.to_s)
    @unmet.relation = 'depends'
    assert_equal('w3m-ssl depends w3m unmet w3m-ssl 0.2.1-1 (provides w3m)', 
		  @unmet.to_s)
  end

#  def test_s_new
#	???
#  end

end
