require File.dirname(__FILE__) +'/test_helper'

MindoroMarine::Acts::Tests.open_db(ENV['DB'])
class ActsAsHausdorffSpaceTest < Test::Unit::TestCase
  
  def teardown
  HausdorffSpaceTest.delete_all # irritating. I can't get user_transactional_fixtures = true to work outside the rails testing framework
  end
  
  should "add on " do
    r = HausdorffSpaceTest.new(:name=>'top')
    assert r.save
  end
  
  should 'check one' do
    assert_equal 0, HausdorffSpaceTest.count
  end
end
