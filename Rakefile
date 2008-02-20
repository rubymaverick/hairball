require File.join(File.dirname(__FILE__), "lib", "hairball")
require 'rake'
require 'rake/testtask'

desc "recreate the parser from the treetop grammar file"
task :build do
  puts "calling " + "tt " + File.join(File.dirname(__FILE__), "lib", "hairball", "hairball.treetop")
  exec "tt " + File.join(File.dirname(__FILE__), "lib", "hairball", "hairball.treetop")
end

desc "run all tests"
task :test do
  Rake::TestTask.new do |t|
    t.libs << "test"
    t.test_files = FileList['test/*_test.rb']
    t.verbose = true
  end 
end

desc "run benchmarks to compare Hairball and HAML"
task :benchmark do
  Rake::TestTask.new do |t|
    t.libs << "test"
    t.test_files = FileList['test/*_benchmark.rb']
    t.verbose = true
  end
end

desc "clean out the rbc files"
task :clean do
  rbc_files = Dir["*.rbc"] + Dir["**/*.rbc"]
  rbc_files.each {|f| File.delete(f) }
end

