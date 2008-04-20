require 'rake'
#require 'rake/clean'
require 'rake/testtask'
require 'rake/rdoctask'
require 'rake/gempackagetask'
#require 'rake/contrib/rubyforgepublisher'

SVN_VERSION = %x{svnversion -n '#{File.dirname __FILE__}'}
GEM_VERSION = "0.1." + SVN_VERSION.
  gsub(/:/, '.').
  gsub(/S/, '.2').
  gsub(/M/, '.1')

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

GEM_FILES = docs.rdoc_files + FileList['Rakefile']

spec = Gem::Specification.new do |s|
  s.platform = Gem::Platform::RUBY
  s.name = 'mplayer'
  s.version = GEM_VERSION
  s.date = Date.today.to_s
  s.authors = ["Steve Sloan"]
  s.summary = 'Provides a Ruby interface to MPlayer'
#  s.description =
  s.files = GEM_FILES.to_a.delete_if {|f| f.include?('.svn')}
  s.autorequire = 'mplayer'
  s.test_files = Dir["test/**/test_*.rb"]
  s.add_dependency 'rake', '> 0.7.0'

  s.has_rdoc = true
  s.extra_rdoc_files = docs.rdoc_files.reject { |fn| fn =~ /\.rb$/ }.to_a
  s.rdoc_options = docs.options
end
Rake::GemPackageTask.new spec  do |pkg|
  pkg.need_zip = true
  pkg.need_tar = true
end

task :default => :test

#load 'publish.rf' if File.exist? 'publish.rf'


