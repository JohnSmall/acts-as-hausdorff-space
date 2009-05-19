# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{acts-as-hausdorff-space}
  s.version = "0.1.4"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["John Small"]
  s.date = %q{2009-05-19}
  s.email = %q{jds340@gmail.com}
  s.extra_rdoc_files = [
    "LICENSE",
     "README.rdoc"
  ]
  s.files = [
    ".document",
     ".gitignore",
     "LICENSE",
     "README.rdoc",
     "Rakefile",
     "VERSION.yml",
     "acts-as-hausdorff-space.gemspec",
     "design_idea.rdoc",
     "doc/LICENSE.html",
     "doc/MindoroMarine.html",
     "doc/MindoroMarine/Acts.html",
     "doc/MindoroMarine/Acts/HausdorffSpace.html",
     "doc/MindoroMarine/Acts/HausdorffSpace/ActMethods.html",
     "doc/MindoroMarine/Acts/HausdorffSpace/ClassMethods.html",
     "doc/MindoroMarine/Acts/HausdorffSpace/Gap.html",
     "doc/MindoroMarine/Acts/HausdorffSpace/HSArray.html",
     "doc/MindoroMarine/Acts/HausdorffSpace/InstanceMethods.html",
     "doc/MindoroMarine/Acts/HausdorffSpace/VirtualRoot.html",
     "doc/README_rdoc.html",
     "doc/created.rid",
     "doc/images/brick.png",
     "doc/images/brick_link.png",
     "doc/images/bug.png",
     "doc/images/bullet_black.png",
     "doc/images/bullet_toggle_minus.png",
     "doc/images/bullet_toggle_plus.png",
     "doc/images/date.png",
     "doc/images/find.png",
     "doc/images/loadingAnimation.gif",
     "doc/images/macFFBgHack.png",
     "doc/images/package.png",
     "doc/images/page_green.png",
     "doc/images/page_white_text.png",
     "doc/images/page_white_width.png",
     "doc/images/plugin.png",
     "doc/images/ruby.png",
     "doc/images/tag_green.png",
     "doc/images/wrench.png",
     "doc/images/wrench_orange.png",
     "doc/images/zoom.png",
     "doc/index.html",
     "doc/js/darkfish.js",
     "doc/js/jquery.js",
     "doc/js/quicksearch.js",
     "doc/js/thickbox-compressed.js",
     "doc/lib/acts-as-hausdorff-space_rb.html",
     "doc/lib/acts_as_hausdorff_space_rb.html",
     "doc/rdoc.css",
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
  s.homepage = %q{http://github.com/JohnSmall/acts-as-hausdorff-space}
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.3}
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
    s.specification_version = 3

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end
