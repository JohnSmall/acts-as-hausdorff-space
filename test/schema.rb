ActiveRecord::Schema.define(:version => 0) do

  create_table "hausdorff_space_tests", :force => true do |t|
    t.string   "name"
    t.decimal  "left_col",        :precision => 63, :scale => 30
    t.decimal  "right_col",        :precision => 63, :scale => 30
  end

  add_index "hausdorff_space_tests", ["left_col"], :name => "lft_idx"
  add_index "hausdorff_space_tests", ["right_col"], :name => "rgt_idx"

end
