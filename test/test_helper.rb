ENV["RAILS_ENV"] = "test"
require 'rubygems'
require 'activerecord'
require File.dirname(__FILE__)+'/../lib/acts-as-hausdorff-space'
require 'test/unit'
require 'shoulda'

class HausdorffSpaceTest < ActiveRecord::Base
acts_as_hausdorff_space :left_column=>'left_col',:right_column=>'right_col'
end


#class Test::Unit::TestCase
# use_transactional_fixtures = false
#end

module MindoroMarine
  module Acts
    module Tests
     def self.open_db(db_name='sqlite3')
     config = YAML::load(IO.read(File.dirname(__FILE__) + '/database.yml'))
     ActiveRecord::Base.logger = Logger.new(File.dirname(__FILE__) + '/debug.log')
     cs = ActiveRecord::Base.establish_connection(config[db_name])
     puts "Using #{cs.connection.class.to_s} adapter" 
     load(File.dirname(__FILE__) + '/schema.rb')
     end
    end
  end
end
