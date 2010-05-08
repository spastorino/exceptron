# encoding: UTF-8
require File.expand_path("../lib/exceptron/version", __FILE__)

Gem::Specification.new do |s|
  s.name = "exceptron"
  s.rubyforge_project = "exceptron"
  s.version = Exceptron::VERSION.dup

  s.authors = ["José Valim"]
  s.description = "Exceptron cames from the future to make your exceptions rock!"

  s.files = Dir["lib/**/*.rb"] + %w(README.rdoc MIT-LICENSE)
  s.test_files = Dir["test/**/*"]
  s.extra_rdoc_files = ["README.rdoc"]

  s.homepage = "http://github.com/jorlhuda/exceptron"
  s.rdoc_options = ["--main", "README.rdoc"]
  s.require_paths = ["lib"]
  s.rubygems_version = "1.3.6"
  s.summary = "Exceptron cames from the future to make your exceptions rock!"
end