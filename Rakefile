require 'rubygems'
require 'rake'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "acts-as-hausdorff-space"
    gem.summary = %Q{Use real numbers instead of integers for nested sets because real numbers are a Hausdorff space}
    gem.email = "jds340@gmail.com"
    gem.homepage = "http://github.com/JohnSmall/acts-as-hausdorff-space"
    gem.authors = ["John Small"]

    # gem is a Gem::Specification... see http://www.rubygems.org/read/chapter/20 for additional settings
  end
rescue LoadError
  puts "Jeweler not available. Install it with: sudo gem install technicalpickles-jeweler -s http://gems.github.com"
end

require 'rake/testtask'
#Rake::TestTask.new(:test) do |test|
#  test.libs << 'lib' << 'test'
#  test.pattern = 'test/**/*_test.rb'
#  test.verbose = true
#end

desc 'Run tests on all database adapters.'
task :default => [:test_mysql, :test_sqlite3, :test_postgresql]
for adapter in %w(mysql postgresql sqlite3)
  Rake::TestTask.new("test_#{adapter}") do |t|
    t.libs << 'lib'
    t.pattern = "test/#{adapter}.rb"
    t.verbose = true
  end
end

begin
  require 'rcov/rcovtask'
  Rcov::RcovTask.new do |test|
    test.libs << 'test'
    test.pattern = 'test/**/*_test.rb'
    test.verbose = true
  end
rescue LoadError
  task :rcov do
    abort "RCov is not available. In order to run rcov, you must: sudo gem install spicycode-rcov"
  end
end

task :default => :test

require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  if File.exist?('VERSION.yml')
    config = YAML.load(File.read('VERSION.yml'))
    version = "#{config[:major]}.#{config[:minor]}.#{config[:patch]}"
  else
    version = ""
  end
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "acts-as-hausdorff-space #{version}"
  rdoc.rdoc_files.include('*.rdoc')
  rdoc.rdoc_files.include('lib/**/*.rb')
end



