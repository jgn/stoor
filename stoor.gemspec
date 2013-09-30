$LOAD_PATH.unshift File.expand_path(File.join('..', 'lib'), __FILE__)
require 'stoor/version'

Gem::Specification.new do |s|
  s.name          = 'stoor'
  s.version       = Stoor::VERSION
  s.date          = Time.now.utc.strftime('%Y-%m-%d')
  s.summary       = 'Front-end for Gollum'
  s.description   = 'Stoor is an app to bring up a local Gollum (wiki software) against a Git repo with bells and whistles like auth.'
  s.license       = 'MIT'
  s.authors       = ['John G. Norman']
  s.email         = 'john@7fff.com'
  s.files         = `git ls-files`.split("\n")
  s.homepage      = 'https://github.com/jgn/stoor'
  s.rdoc_options  = ['--charset=UTF-8']
  s.require_paths = ['lib']
  s.test_files    = `git ls-files spec`.split("\n")
  s.add_dependency 'thin',                '~> 1.5.1'
  s.add_dependency 'gollum',              '~> 2.5.0'
  s.add_dependency 'sinatra_auth_github', '~> 1.0.0'
  s.add_dependency 'json',                '~> 1.8.0'
  s.add_dependency 'grit',                '~> 2.5.0'
  s.executables << 'stoor'

  s.add_development_dependency 'rack-test'
  s.add_development_dependency 'rspec'
end
