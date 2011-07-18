# -*- encoding: utf-8 -*-
Gem::Specification.new do |gem|
  gem.name = 'mplayer'
  gem.version = '1.0.0'
  gem.date = '2011-07-02'
  gem.platform = Gem::Platform::RUBY

  gem.authors = ['Steve Sloan', 'Marc Lagrange', 'Peter Rullmann']
  gem.email = ['steve@finagle.org']
  gem.homepage = 'http://github.com/CodeMonkeysteve/ruby-mplayer'
  gem.summary = "Ruby interface to MPlayer"
  gem.description = "Provides a Ruby interface to MPlayer"

  gem.required_rubygems_version = ">= 1.3.6"

  gem.add_dependency('eventmachine')
  gem.add_dependency('em-synchrony')

  gem.add_development_dependency('rspec')
  gem.add_development_dependency('rr')
  gem.add_development_dependency('guard-rspec')

  gem.files = %w(MIT-LICENSE README.rdoc) + Dir["{lib,test}/**/*"]
  gem.test_files = Dir['test/**/test_*.rb']
  gem.require_paths = ['lib']
end

