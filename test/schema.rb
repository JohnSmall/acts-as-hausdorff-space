ActiveRecord::Schema.define(:version => 0) do

  create_table "hausdorff_space_tests", :force => true do |t|
    t.string   "name"
    t.decimal  "lft",        :precision => 63, :scale => 30
    t.decimal  "rgt",        :precision => 63, :scale => 30
  end

  add_index "hausdorff_space_tests", ["lft"], :name => "lft_idx"
  add_index "hausdorff_space_tests", ["rgt"], :name => "rgt_idx"

end
