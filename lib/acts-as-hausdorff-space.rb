# acts_as_hausdorff_space
# (c) John Small 2009
require "acts_as_hausdorff_space"

ActiveRecord::Base.class_eval do
  include MindoroMarine::Acts::HausdorffSpace
end
