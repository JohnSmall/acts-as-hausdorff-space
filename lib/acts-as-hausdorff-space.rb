# acts_as_hausdorff_space
# (c) John Small 2009
unless ENV["RAILS_ENV"] = "test"
  require "acts_as_hausdorff_space"
else
  require "../lib/acts_as_hausdorff_space"
end  

ActiveRecord::Base.class_eval do
  include MindoroMarine::Acts::HausdorffSpace
end
