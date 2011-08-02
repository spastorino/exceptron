# encoding: UTF-8
require File.expand_path("../lib/exceptron/version", __FILE__)

Gem::Specification.new do |s|
  s.name = "exceptron"
  s.rubyforge_project = "exceptron"
  s.version = Exceptron::VERSION.dup

  s.authors = ["Santiago Pastorino", "José Valim"]
  s.description = "Exceptron comes from the future to make your exceptions rock!"

  s.files = Dir["lib/**/*.{rb,erb}"] + %w(README.rdoc MIT-LICENSE)
  s.test_files = Dir["test/**/*"]
  s.extra_rdoc_files = ["README.rdoc"]

  s.add_runtime_dependency 'rails',      '~> 3.1.0.rc1'

  s.add_development_dependency 'sqlite3'

  s.homepage = "http://github.com/jorlhuda/exceptron"
  s.rdoc_options = ["--main", "README.rdoc"]
  s.require_paths = ["lib"]
  s.rubygems_version = "1.3.6"
  s.summary = "Exceptron comes from the future to make your exceptions rock!"
end
