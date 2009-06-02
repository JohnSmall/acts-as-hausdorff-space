# ActsAsHausdorffSpace
module MindoroMarine
  module Acts #:nodoc:
    module HausdorffSpace #:nodoc:
    
     def self.included(base)
        base.extend(ActMethods)              
      end
    module ActMethods
      # Configuration options are:        
        # * +left_column+ - Column name for the left index (default: +lft+). 
        # * +right_column+ - Column name for the right index (default: +rgt+). NOTE: 
        #   Don't use +left+ and +right+, since these are reserved database words.        
        # * +bias+ - A divisor used to calculate where in a gap a new record should go. Bigger numbers are preferred for wide shallow trees
        #   Default is 1E6
        # * +max_double+ - This is the outer left and right boundaries of all the trees. Set it according to the precision and scale you're
        #  using in your database columns. Default is 1E20
        def acts_as_hausdorff_space(options = {}) 
        #[TODO] use reverse merge here
        write_inheritable_attribute(:acts_as_hausdorff_space_options,
             { :left_column    => (options[:left_column]   || 'lft'),
               :right_column   => (options[:right_column]  || 'rgt'),
               :bias           => (options[:bias]  || 1E6),
               :max_double     => (options[:max_double] || 1E20 ),                          
               :class          => self , # for single-table inheritance
               :virtual_root   => VirtualRoot.new(-(options[:max_double] || 1E20 ),
                                                   (options[:max_double] || 1E20 ))
              } )
          
          class_inheritable_reader :acts_as_hausdorff_space_options
          unless included_modules.include? MindoroMarine::Acts::HausdorffSpace::InstanceMethods
             include MindoroMarine::Acts::HausdorffSpace::InstanceMethods
             extend MindoroMarine::Acts::HausdorffSpace::ClassMethods
          end
        end
    end  
    
    # Each branch has branches and/or leaves and gaps to put new things in
    # A gap has attributes left_col_val and right_col_val 
    class Gap 
     attr_accessor :left_col_val,:right_col_val
    end   
    
    # An instance of VirtualRoot is a hidden root that "owns" the actual roots. It's only here so we can use the same code for
    # real roots and children. Otherwise we have to write special code for the top level parents.
    # Note: This is very different from the concept of virtual roots in better_nested_set which is the equivalent of <Klass>.root.children
    # to get the immediate children of a top level root    
    class VirtualRoot
    attr_accessor :left_col_val,:right_col_val
    attr_reader :children
    
    # initialize with a left and right value that will be the bounds of the entire tree of all the roots
    def initialize( left_val,right_val)
     self.left_col_val = left_val
     self.right_col_val = right_val
     @children = HSArray.new
     @children.parent = self
    end
   
    def save
      @children.each{|child| child.save}
    end 
    
    end #VirtualRoot
    
    # We need an array to hold children, but because we don't use parent_id we can't return the children as an AR has_many association
    # Therefore we use an array.  Because we want to be able to write 
    # <tt>parent.children << SomeModel.new</tt>
    # then we need to do special stuff in "<<". But we don't want to mixin into Array because that might (almost certainly would)
    # mess up other code, so we'll get very Java-like and subclass Array
    class HSArray < Array
    attr_accessor :parent
    
        # subclass << to set the parent on the new items being added
        def <<(elem)
        if elem.is_a?(Array) # if it is an array then load each item into the HSArray in turn
         elem.each do |item| 
         self << item
         end
        else
         super
         elem.parent = self.parent if self.parent && elem.respond_to?('parent')                  
        end         
       end #<<(elem) 
    end #HSArray
    
   
    module ClassMethods
        
    # Get all the top level roots. This does a find of all records with no immediate parent in the database. 
    # When they're loaded they get a virtual root attached as their parent. This is to make sure that every node has a parent which helps to
    # generalise and simplify the code for working out left and right boundaries. 
    def in_tree_load?
      @in_tree_load == true
    end
       
    def in_tree_load=(loading_tree)
      @in_tree_load=loading_tree
    end
    
    def roots
     self.in_tree_load = true
     begin
     top_levels =    self.find( :all, :conditions => "not exists (select t1.id from #{self.table_name} t1
                                                                       where t1.#{left_col_name} <#{self.table_name}.#{left_col_name} 
                                                                       and t1.#{right_col_name} > #{self.table_name}.#{right_col_name}) 
                                                                       and #{self.table_name}.#{right_col_name} is not null 
                                                                       and #{self.table_name}.#{left_col_name} is not null",
                                                                       :order=>"#{left_col_name}")
     self.virtual_root.children.clear
     top_levels.each do |tl|
        self.virtual_root.children << tl
        end
     ensure
     self.in_tree_load = false
     end
    end # def roots
    
    # get the first root from roots
    def root
        roots.first
    end
    # use the instance method <tt>build_full_tree</tt> on the root to get all the children set up in a tree
    def full_tree
      root.build_full_tree
    end
 
    # Return the left column name. Either the one supplied in the options to acts_as_hausdorff_space or the default "lft"
    def left_col_name
        acts_as_hausdorff_space_options[:left_column]
    end
    
    # Return the right column name. Either the one supplied in the options to acts_as_hausdorff_space or the default "rgt"
    def right_col_name
        acts_as_hausdorff_space_options[:right_column]
    end
    
    # Return the max_double supplied in the options to to acts_as_hausdorff_space or the default 1E20
    def max_double
      acts_as_hausdorff_space_options[:max_double]
    end
    
     # Return the bias supplied in the options to to acts_as_hausdorff_space or the default 1E6
    def bias
      acts_as_hausdorff_space_options[:bias]
    end
    # Return the virtual root. This is an in memory only parent to all the roots, the left is set to -max_double and the right to max_double
    def virtual_root 
     acts_as_hausdorff_space_options[:virtual_root]
    end
        
    end #module ClassMethods
    
    ############################ INSTANCE METHODS ######################################################
    module InstanceMethods
    attr_accessor :in_tree
    
    # initialize isn't always called so we can't do this in initialize. This sets up things we need to hold the tree together 
    def after_initialize 
     @parent = nil    
     @children = HSArray.new
     @children.parent = self
     @root = nil
     @is_root=false
     #@in_tree = false
     @prev_left = nil
     @prev_right = nil
     @new_parent = false
     @needs_moving = false
     @state = 0
    end
    
    
    
    # Short hand method to save typing self.class.left_col_name
    def left_col_name
      self.class.left_col_name
    end
    
    # Short hand method to save typing self.class.right_col_name
    def right_col_name
      self.class.right_col_name
    end
    
    # get the left col value
    def left_col_val
       read_attribute(left_col_name)
    end
    
    # set the left col value
    def left_col_val=(value)
       write_attribute(left_col_name,value)
    end  
    
    # get the right col value
    def right_col_val
      read_attribute(right_col_name)
    end
    
    # set the right col value
    def right_col_val=(value)
       write_attribute(right_col_name,value)
    end 
    
    # Get the parent.
    # If the parent hasn't already been set, and if we're not building the full tree (which sets parents) and if we've
    # got a valid lft and right then construct the SQL to get the parent from the DB. If none is found then it's a root so
    # set the parent to be the class.virtual_root
    # If the parent is already set then don't go to the database to look for it, just return it
    def parent
   #  if !in_tree && left_col_val && right_col_val && !@parent # only get the parent by SQL if we don't know what it is
   #  @parent = self.class.find :first, :conditions => " #{left_col_val} > #{self.class.left_col_name} and #{left_col_val} < #{self.class.right_col_name} ",:order =>'#{self.class.left_col_name} DESC'
   #      if !@parent        
          # @is_root = (lft == rgt) || (id == root.id)
   #        return self.class.virtual_root
   #      end 
   #  else
     @parent
   #  end
    end
    
    # set a new parent. This will save the parent, which will force a save of this child after the parent has had its lft and rgt set
    # If we're loading a full tree, we don't save the parent and child as that would be daft
    # we can add children to parents via parent.children << a_record or a_record.parent = parent. The 2nd form doesn't go
    # through the overridden << method on array, so we have to force it to.
    def parent=(new_parent)
     if @parent != new_parent
        if new_parent.children.include?(self)
          @parent = new_parent
          unless self.class.in_tree_load?
            needs_moving! 
            @new_parent = true
          end  
          @is_root  = @parent.is_a?(VirtualRoot) 
        else
         new_parent.children << self # if we entered this method via record.parent = parent
        end   
     end  
     # [TODO] clean this up with parent.save_children 
     # unless in_tree # if we're loading the tree then don't do this
     #  @needs_moving = true # if it needs moving then before_save will set lft and rgt
       parent.save unless self.class.in_tree_load?  || @parent.is_a?(VirtualRoot)        
     #end  
     return @parent
    end
    
    # sets the in_tree flag, pulls in all the children of this record with the level set correctly and ordered by lft.
    # Then it executes a private method which does a depth first recursion of the returned dataset to build the tree.
    # Returns this record as the root of the tree
    def build_full_tree
    self.class.in_tree_load = true
    begin
    # get all the children with levels counted and ordered in one SQL statement - this is what nested sets are all about 
    # then do a depth first traversal of all the entire list to build the tree in memory
      child_list = self.class.find_by_sql("SELECT t1.*,(select count(*) from #{self.class.table_name} t2 where t2.#{left_col_name}<t1.#{left_col_name} and t2.#{right_col_name} > t1.#{right_col_name}) as depth from #{self.class.table_name} t1 where t1.#{left_col_name} >#{left_col_val} and t1.#{right_col_name} <#{right_col_val} order by #{left_col_name} desc")
     # child_list.each{|r| r.in_tree = true}
    #for some strange reason depth comes back as a string in Postgresql hence the .to_i      
      build_tree_by_recursion(self,child_list.last.depth.to_i,child_list) unless child_list.size == 0
    ensure
      self.class.in_tree_load  = false
    end
    return self  
end

# get the gap on the left of this record
def lft_gap
  gap = Gap.new
  gap.right_col_val = self.left_col_val
 if parent.children.first == self  
  gap.left_col_val = parent.left_col_val 
 else
  prev_index = parent.children.index(self)-1
  gap.left_col_val = parent.children[prev_index].right_col_val
 end
 return gap 
end

# get the gap on the right of this record
def rgt_gap
 gap = Gap.new
 gap.left_col_val = self.right_col_val
 if parent.children.last == self  
  gap.right_col_val = parent.right_col_val 
 else
 next_index = parent.children.index(self)+1
 gap.right_col_val =  parent.children[next_index].left_col_val
 end 
 return gap
end # rgt_gap

# is this record a root
def is_root?
  @is_root
end

# find the root that owns this record. This is called "my_root" rather than "root" so you don't mix it up with <class>.root
# This is different to how it's done in acts_as_nested_set
def my_root
  unless @root
#  puts "get my_root conditions #{left_col_val} >= #{left_col_name} and #{right_col_val}<= #{right_col_name}  "
  @root = (self.class.find :first, :conditions => " #{left_col_val} >= #{left_col_name} and #{right_col_val}<= #{right_col_name} ",:order =>"#{left_col_name}") #between includes the end points
  else
  @root
  end
end

# Find the immediate children of this record. If the children have already been loaded before either via build_full_tree or
# a previous call to children then this just returns what was previously loaded. Otherwise it goes to the database.
# The sql is a bit more involved than used in acts_as_nested_set because this is a pure nested set model and there's no parent_id
# Because we're not using parent_id the returned array is not an AR associattion, unlike acts_as_nested_set. You have been warned.
def children    
    unless ( @children.size>0 || ( left_col_val == right_col_val ) || self.class.in_tree_load?) # don't get children unless lft is not equal to rgt 
     # puts "load_tree = #{in_tree}"    
      @children << self.class.find( :all,:conditions => " #{self.class.table_name}.#{left_col_name} >#{left_col_val} and #{self.class.table_name}.#{right_col_name} < #{right_col_val} and #{left_col_val} = (select max(t1.#{left_col_name}) from #{self.class.table_name} t1 where #{self.class.table_name}.#{left_col_name} between t1.#{left_col_name} and t1.#{right_col_name})" )
   else
      @children
   end
end

# Where most of the clever action happens.
# 1. If we haven't got a parent and it's not a new record then leave things alone. This allows us to update
#    records in isolation without messing with tree positions
# 2. If there's no parent then set the <class>.virtual_root to be the parent before continuing
# 3. Find the left boundary and the right boundary from the parent or the siblings or both
# 4. If this record has no children then set lft=rgt and put it well on the left of the gap
# 5. If there are children then set the lft and rgt to a comfortable size to hold the children
=begin
def before_save
if new_record? || parent
puts 'ok ready to calc lft and rgt'
 if !@parent
   self.class.roots # this loads virtual_root with roots
   self.class.virtual_root.children << self  # if we haven't got a parent then make the virtual root the parent
 end
 if @needs_moving || new_record? # we only calculate lft and rgt if it's a new record or if the parent has changed
   puts "needs moving = #{@needs_moving} new_record = #{new_record?}"
  calc_lft_and_rgt 
  @needs_moving = false
end
end  
end
=end

def before_create
 if !@parent 
   #puts "before create set parent"
   self.class.roots # this loads virtual_root with roots
   self.class.virtual_root.children << self  # if we haven't got a parent then make the virtual root the parent
 end
  calc_lft_and_rgt
  true
end

def before_update
  if @new_parent || children.size > 0
  # puts "before update set left and right id = #{id}"
   calc_lft_and_rgt 
   @new_parent = false
   true # this must return true after setting @needs_moving to false or the record won't be saved
  end  
end

# Where most of the remaining action happens
# If we've moved the record into a new parent from somewhere else then we need to update the old child records
# to bring those into place. This requires a scaling, to fit into the new gap, and a translation to move into the corrent place
# The code works out the values required for a single SQL statement that pulls the entire branch across
#
# If we haven't moved from elsewhere then save each child that needs saving
# If we haven't got a parent then leave things alone - this allows records to be updated in isolation
def after_save
 if parent
  if @needs_moving && @children.size > 0 # if we're moving from somewhere else
        @children.clear
        scale = ((right_col_val-left_col_val)/(@prev_right - @prev_left)).abs
        old_mid_point = (@prev_right + @prev_left)/2
        new_mid_point = (right_col_val+left_col_val)/2
        sql = "update #{self.class.table_name}  set #{left_col_name} = ((#{left_col_name} - #{old_mid_point})*#{scale})+#{new_mid_point}, #{right_col_name} = ((#{right_col_name} - #{old_mid_point})*#{scale})+#{new_mid_point} where #{left_col_name} >#{@prev_left} and #{right_col_name} < #{@prev_right} "       
        connection.update_sql(sql)
        @needs_moving =false
        build_full_tree # get the children back        
  else  
        @children.each{|child| child.save if !(child.left_col_val && child.right_col_val) } # save only the ones that need lft and rgt
  end
  @prev_left = @prev_right = nil
  @new_parent = false
 end   
end

# get the siblings. All immediate children of the parent minus self
def siblings
  if parent
   self_and_siblings.reject{|r| r == self}
  end
end

# get all children of the parent of this record
def self_and_siblings
 if parent
   parent.children
  end
end
# get the line of owners with the root first 
def self_and_ancestors
  self.class.find :all, :conditions =>"#{left_col_name} <= #{left_col_val} and #{right_col_name} >= #{right_col_val} ",:order=>"#{left_col_name}"
end

# self_and_ancestors with self removed
def ancestors
 self_and_ancestors.reject{|r| r == self}
end

# find all children at any depth with lft=rgt
def leaf_nodes
  self.class.find :all,:conditions => " #{left_col_name} >#{left_col_val} and #{right_col_name} < #{right_col_val} and #{left_col_name} = #{right_col_name}" 
end

# find the mid point of the gap this record fits in
def mid_point
   (furthrest_left+furthrest_right)/2
end

# if the record needs moving then save the old lft and rgt and set the current lft and rgt to nil so we can work out the scaling and translation parameters
def needs_moving!  
   if left_col_val && right_col_val && !self.class.in_tree_load?
    @prev_left = left_col_val
    self.left_col_val = nil
    @prev_right = right_col_val
    self.right_col_val = nil
    @needs_moving = true
   end  
end 
 
=begin  
def scale_and_translate(move_to_origin,scale_by,translate_by)
 self.lft = ((self.lft - move_to_origin)*scale_by) + translate_by
 self.lft = ((self.lft - move_to_origin)*scale_by) + translate_by
 children.each{|child| child.scale_and_translate(move_to_origin,scale_by,translate_by)}
end
=end

private

# calculate the left and right based on the parent and the siblings
def calc_lft_and_rgt
far_left =  furthrest_left
   far_right = furthrest_right
   gap = far_right - far_left
  if  @children.size>0 
     self.left_col_val = far_left + gap/4 
     self.right_col_val = far_right - gap/4   
  else    
     self.left_col_val = self.right_col_val = far_left+(gap/self.class.bias)       
  end
end
  
def furthrest_left
   lft_gap.left_col_val 
end

def furthrest_right
  #puts 'in furthrest_right '
  rgt_gap.right_col_val 
end 

# this assumes a nicely ordered tree such that the next depth is always one more tha the existing depth
# otherwise throw a wobbly
# the strange .to_i has to be there because depth can come back from the db as a string
def build_tree_by_recursion(parent,depth,ar_results)
 while ar_results.size > 0 && ar_results.last.depth.to_i >= depth
     if ar_results.last.depth.to_i == depth 
        current_record = ar_results.pop
      #  puts "curr record in tree =#{current_record.id} parent in tree = #{parent.id}"
        parent.children << current_record
        #current_record.in_tree = false
     #   puts " child added #{parent.children.include?(current_record)}"
      #  puts "+++"
     elsif ar_results.last.depth.to_i == (depth + 1) 
       # current_record.in_tree = true
        build_tree_by_recursion(current_record,ar_results.last.depth.to_i,ar_results)
       # current_record.in_tree = false
     elsif ar_results.last.depth.to_i > (depth + 1)  
       raise "badly formed nested set result set"          
     end
 end # while
end # def build_tree_by_recursion(parent,depth,ar_results)
    
    
    end #module InstanceMethods
    end # module HausdorffSpace
  end #module Acts 
end#module MindoroMarine 
