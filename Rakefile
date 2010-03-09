require 'rake'
require 'rake/testtask'
 
begin
  require 'jeweler'
  Jeweler::Tasks.new do |s|
    s.name = "magic_meta_methods"
    s.summary = "A gem that polishes ActiveRecord data serialization to make it really awesome"
    s.description = "magic_meta_methods uses ActiveRecord data serialization and allows for several objects by key to be stored in _one_ column while still providing the same attr_accessor behavior as if there were a column for _each_ serialized object - hence the magic 'meta' methods"
    s.email = "techwhizbang@gmail.com"
    s.homepage = "http://github.com/techwhizbang/magic_meta_methods"
    s.rubyforge_project = 'magic_meta_methods'
    s.authors = ["Nick Zalabak"]
    s.files =  FileList["[A-Za-z]*", "{lib,test}/**/*"]
    s.test_files = FileList["test/**/*"]
    s.add_dependency "activerecord", ">= 2.3.2"
  end
 
rescue LoadError
  puts "Jeweler not available. Install it with: gem install jeweler"
end
 
Rake::TestTask.new do |t|
  t.libs << 'lib'
  t.pattern = 'test/**/*_test.rb'
  t.verbose = false
end
 
task :default => :test
