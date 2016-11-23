# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'pgmove/version'

Gem::Specification.new do |spec|
  spec.name          = "pgmove"
  spec.version       = Pgmove::VERSION
  spec.authors       = ["Neeraj"]
  spec.email         = [""]

  spec.summary       = %q{A tool to move postgres databases b/w clusters using bucardo}
  spec.description   = %q{A tool to move postgres databases b/w clusters using bucardo}

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "pg", "~> 0.19.0"
  spec.add_development_dependency "bundler", "~> 1.12"
  spec.add_development_dependency "rake", "~> 10.0"
end
