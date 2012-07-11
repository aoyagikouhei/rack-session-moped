# -*- encoding: utf-8 -*-
require File.expand_path('../lib/rack-session-moped/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["aoyagikouhei"]
  gem.email         = ["aoyagi.kouhei@gmail.com"]
  gem.description   = %q{TODO: Write a gem description}
  gem.summary       = %q{TODO: Write a gem summary}
  gem.homepage      = ""

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "rack-session-moped"
  gem.require_paths = ["lib"]
  gem.version       = Rack::Session::Moped::VERSION
end
