# -*- encoding: utf-8 -*-
require File.expand_path('../lib/Parsistence/version', __FILE__)

Gem::Specification.new do |s|
  s.name        = "Parsistence"
  s.version     = Parsistence::VERSION
  s.authors     = ["Jamon Holmgren", "Silas J. Matson", "Alan deLevie"]
  s.email       = ["jamon@clearsightstudio.com", "silas@clearsightstudio.com", "adelevie@gmail.com"]
  s.homepage    = "https://github.com/clearsightstudio/Parsistence"
  s.summary     = %q{Your models on RubyMotion and Parse in a persistence.js style pattern.}
  s.description = %q{Your models on RubyMotion and Parse in a persistence.js style pattern.}

  s.rubyforge_project = "Parsistence"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  # specify any dependencies here; for example:
  # s.add_development_dependency "rspec"
  # s.add_runtime_dependency "rest-client"
end
