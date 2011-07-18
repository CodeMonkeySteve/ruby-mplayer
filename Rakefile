require 'rake'
#require 'rake/clean'
require 'rake/testtask'
require 'rake/rdoctask'
require 'rake/gempackagetask'
#require 'rake/contrib/rubyforgepublisher'

Rake::TestTask.new do |t|
  t.test_files = FileList['test/test_*.rb']
  t.verbose = true
end

docs = Rake::RDocTask.new :rdoc do |rdoc|
  rdoc.rdoc_dir = 'html'
  rdoc.title    = "MPlayer-Ruby Reference"
  rdoc.options += ['--line-numbers', '--inline-source']
  rdoc.rdoc_files.include 'MIT-LICENSE' #, 'README'
  rdoc.rdoc_files.include 'lib/**/*.rb'
end

task :default => :test

#load 'publish.rf' if File.exist? 'publish.rf'


