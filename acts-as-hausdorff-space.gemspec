# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{acts-as-hausdorff-space}
  s.version = "0.1.3"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["John Small"]
  s.date = %q{2009-04-25}
  s.email = %q{jds340@gmail.com}
  s.extra_rdoc_files = [
    "LICENSE",
    "README.rdoc"
  ]
  s.files = [
    "LICENSE",
    "README.rdoc",
    "Rakefile",
    "VERSION.yml",
    "lib/acts-as-hausdorff-space.rb",
    "lib/acts_as_hausdorff_space.rb",
    "test/acts_as_hausdorff_space_test.rb",
    "test/database.yml",
    "test/mysql.rb",
    "test/postgresql.rb",
    "test/schema.rb",
    "test/sqlite3.rb",
    "test/test_helper.rb"
  ]
  s.has_rdoc = true
  s.homepage = %q{http://github.com/JohnSmall/acts-as-hausdorff-space}
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.1}
  s.summary = %q{Use real numbers instead of integers for nested sets because real numbers are a Hausdorff space}
  s.test_files = [
    "test/schema.rb",
    "test/sqlite3.rb",
    "test/mysql.rb",
    "test/test_helper.rb",
    "test/acts_as_hausdorff_space_test.rb",
    "test/postgresql.rb"
  ]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 2

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end
