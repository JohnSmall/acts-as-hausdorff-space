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
        #   (if it isn't there already) and use that as the foreign key restriction. It's also possible 
        #   to give it an entire string that is interpolated if you need a tighter scope than just a foreign key.
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
    # little things we need
    
    # Each branch has branches and/or leaves and gaps to put new things in
    # A gap has attributes left_col_val and right_col_val 
    class Gap 
     attr_accessor :left_col_val,:right_col_val
    end   
    
    # An instance of VirtualRoot is a hidden root that "owns" the actual roots. It's only here so we can use the same code for
    # real roots and children. Otherwise we have to write special code for the top level parents
    
    class VirtualRoot
    attr_accessor :left_col_val,:right_col_val
    attr_reader :children
    def initialize( left_val,right_val)
     self.left_col_val = left_val
     self.right_col_val = right_val
     @children = HSArray.new
     @children.parent = self
    end
    
    end #VirtualRoot
    
     # We need an array to hold children. Because we want to be able to write parent.children << SomeModel.new
    # then we need to do special stuff in "<<" but we don't want to mixin into Array because that might (almost certainly would)
    # mess up other code, so we'll get very javary and subclass Array
    class HSArray < Array
    attr_accessor :parent
    
        def <<(elem)
        if elem.is_a?(Array) # if it is an array then load each item into the HSArray in turn
         elem.each do |item| 
         #puts "each item #{elem.class.name} item #{item.class.name}"
         self << item
         end
        else
         super  
         #puts "add one #{elem.class.name}"
         elem.parent = self.parent if self.parent && elem.respond_to?('parent') 
        end         
       end #<<(elem) 
    end #HSArray
    
   
    module ClassMethods
        
        
    def roots
     top_levels =    self.find( :all, :conditions => "not exists (select t1.id from #{self.table_name} t1
                                                                       where t1.#{left_col_name} <#{self.table_name}.#{left_col_name} 
                                                                       and t1.#{right_col_name} > #{self.table_name}.#{right_col_name})",:order=>"#{left_col_name}")
     self.virtual_root.children.clear
     top_levels.each do |tl|
     begin
     tl.in_tree = true
     self.virtual_root.children << tl
     tl.in_tree = false
     rescue
     tl.in_tree = false
     raise
     end
     end 
    end
    
    def root
        roots.first
    end
    
    def full_tree
      root.build_full_tree
    end
    
    def left_col_name
        acts_as_hausdorff_space_options[:left_column]
    end
    
    def right_col_name
        acts_as_hausdorff_space_options[:right_column]
    end
    
    def max_double
      acts_as_hausdorff_space_options[:max_double]
    end
    
    def bias
      acts_as_hausdorff_space_options[:bias]
    end
    
    def virtual_root 
     acts_as_hausdorff_space_options[:virtual_root]
    end
        
    end #module ClassMethods
    
    ############################ INSTANCE METHODS ######################################################
    module InstanceMethods
    attr_accessor :parent,:in_tree
    
    
    def after_initialize # initialize isn't always called
     @parent = nil    
     @children = HSArray.new
     @children.parent = self
     @root = nil
     @is_root=false
     @in_tree = false
     @prev_left = nil
     @prev_right = nil
    end
    
    def left_col_name
      self.class.left_col_name
    end
    
    def right_col_name
      self.class.right_col_name
    end
    
    def left_col_val
       read_attribute(left_col_name)
    end
    
    def left_col_val=(value)
       write_attribute(left_col_name,value)
    end  
    
    def right_col_val
      read_attribute(right_col_name)
    end
   
    def right_col_val=(value)
       write_attribute(right_col_name,value)
    end 
    
    def parent
     if !in_tree && left_col_val && right_col_val && !@parent # only get the parent by SQL if we don't know what it is
     @parent = self.class.find :first, :conditions => " #{left_col_val} > #{self.class.left_col_name} and #{left_col_val} < #{self.class.right_col_name} ",:order =>'#{self.class.left_col_name} DESC'
         if !@parent        
          # @is_root = (lft == rgt) || (id == root.id)
           return self.class.virtual_root
         end 
     else
     @parent
     end
    end
    
    def parent=(new_parent)
     if @parent != new_parent
        @parent = new_parent
        needs_moving
        @is_root  = @parent.is_a?(VirtualRoot) 
     end  
     # [TODO] clean this up with parent.save_children  
     parent.save unless in_tree || @parent.is_a?(VirtualRoot) 
     return @parent
    end
    
    def build_full_tree
    self.in_tree = true
    begin
    # get all the children with levels counted and ordered in one SQL statement - this is what nested sets are all about 
    # then do a depth first traversal of all the entire list to build the tree in memory
      child_list = self.class.find_by_sql("SELECT t1.*,(select count(*) from #{self.class.table_name} t2 where t2.#{left_col_name}<t1.#{left_col_name} and t2.#{right_col_name} > t1.#{right_col_name}) as depth from #{self.class.table_name} t1 where t1.#{left_col_name} >#{left_col_val} and t1.#{right_col_name} <#{right_col_val} order by #{left_col_name} desc")
      child_list.each{|r| r.in_tree = true}
    #for some strange reason depth comes back as a string in Postgresql hence the .to_i
      build_tree_by_recursion(self,child_list.last.depth.to_i,child_list)
    rescue
    self.in_tree = false
    raise
    end
    return self  
end

def lft_gap
 # puts " in lft gap #{parent.class.name}"
  gap = Gap.new
  gap.right_col_val = self.left_col_val
 if parent.children.first == self  
  gap.left_col_val = parent.left_col_val 
 else
 # puts "get prev index"
  prev_index = parent.children.index(self)-1
 # puts "prev index = #{prev_index} count = #{parent.children.size}"
  gap.left_col_val = parent.children[prev_index].right_col_val
 end
 return gap 
end

def rgt_gap
# puts " in rgt gap #{parent.class.name}"
 gap = Gap.new
 gap.left_col_val = self.right_col_val
 if parent.children.last == self  
  gap.right_col_val = parent.right_col_val 
 else
# puts "get next index"
 next_index = parent.children.index(self)+1
# puts "next index = #{next_index} count = #{parent.children.size}"
 gap.right_col_val =  parent.children[next_index].left_col_val
 end 
 return gap
end # rgt_gap

def is_root?
  @is_root
end

def my_root
  unless @root
  @root = (self.class.find :first, :conditions => " #{left_col_val} >= #{left_col_name} and #{right_col_val}<= #{right_col_name} ",:order =>"#{left_col_name}") #between includes the end points
  else
  @root
  end
end

def children    
    unless ( @children.size>0 || ( left_col_val == right_col_val ) || in_tree) # don't get children unless lft is not equal to rgt 
     # puts "load_tree = #{in_tree}"    
      @children << self.class.find( :all,:conditions => " #{self.class.table_name}.#{left_col_name} >#{left_col_val} and #{self.class.table_name}.#{right_col_name} < #{right_col_val} and #{left_col_val} = (select max(t1.#{left_col_name}) from #{self.class.table_name} t1 where #{self.class.table_name}.#{left_col_name} between t1.#{left_col_name} and t1.#{right_col_name})" )
   else
      @children
   end
end

def before_save
 if !@parent
   self.class.roots # this loads virtual_root with roots
   self.class.virtual_root.children << self  # if we haven't got a parent then make the virtual root the parent
 end
far_left =  furthrest_left
far_right = furthrest_right
#puts "furthrest_right = #{far_right} furthrest_left = #{far_left}"
gap = far_right - far_left
  if  @children.size>0 
     self.left_col_val = far_left + gap/4 
     self.right_col_val = far_right - gap/4   
  else    
     self.left_col_val = self.right_col_val = far_left+(gap/self.class.bias)       
  end
end

def after_save
  if @prev_left && @prev_right && @children.size > 0 # if we're moving from somewhere else
        @children.clear
        scale = ((right_col_val-left_col_val)/(@prev_right - @prev_left)).abs
        old_mid_point = (@prev_right + @prev_left)/2
        new_mid_point = (right_col_val+left_col_val)/2
        sql = "update #{self.class.table_name} t1 set t1.#{left_col_name} = ((t1.#{left_col_name} - #{old_mid_point})*#{scale})+#{new_mid_point}, t1.#{right_col_name} = ((t1.#{right_col_name} - #{old_mid_point})*#{scale})+#{new_mid_point} where t1.#{left_col_name} >#{@prev_left} and t1.#{right_col_name} < #{@prev_right} "       
        connection.update_sql(sql)
        build_full_tree # get the children back
  else   
        @children.each{|child| child.save if !(child.left_col_val && child.right_col_val) } # save only the ones that need lft and rgt
  end
  @prev_left = @prev_right = nil  
end

def siblings
  if parent
   parent.children.reject{|r| r == self}
  end
end

def leaf_nodes
  self.class.find :all,:conditions => " #{left_col_name} >#{left_col_val} and #{right_col_name} < #{right_col_val} and #{left_col_name} = #{right_col_name}" 
end

def mid_point
   (furthrest_left+furthrest_right)/2
end

def needs_moving
   if left_col_val && right_col_val && !in_tree
    @prev_left = left_col_val
    self.left_col_val = nil
    @prev_right = right_col_val
    self.right_col_val = nil
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


def furthrest_left
   lft_gap.left_col_val 
end

def furthrest_right
  rgt_gap.right_col_val 
end 

# this assumes a nicely ordered tree such that the next depth is always one more tha the existing depth
# otherwise throw a wobbly
# the strange .to_i has to be there because depth can come back from the db as a string
def build_tree_by_recursion(parent,depth,ar_results)
 while ar_results.size > 0 && ar_results.last.depth.to_i >= depth
     if ar_results.last.depth.to_i == depth 
        current_record = ar_results.pop
       # puts "curr record in tree =#{current_record.in_tree} parent in tree = #{parent.in_tree}"
        parent.children << current_record
        current_record.in_tree = false
      #  puts "+++"
     elsif ar_results.last.depth.to_i == (depth + 1) 
        current_record.in_tree = true
        build_tree_by_recursion(current_record,ar_results.last.depth.to_i,ar_results)
        current_record.in_tree = false
     elsif ar_results.last.depth.to_i > (depth + 1)  
       raise "badly formed nested set result set"          
     end
 end # while
end # def build_tree_by_recursion(parent,depth,ar_results)
    
    
    end #module InstanceMethods
    end # module HausdorffSpace
  end #module Acts 
end#module MindoroMarine 
