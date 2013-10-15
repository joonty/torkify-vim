# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'torkify/vim/version'

Gem::Specification.new do |spec|
  spec.name          = "torkify-vim"
  spec.version       = Torkify::Vim::VERSION
  spec.authors       = ["Jon Cairns"]
  spec.email         = ["jon@ggapps.co.uk"]
  spec.description   = %q{Vim quickfix integration with torkify}
  spec.summary       = %q{Vim quickfix integration with torkify}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "json"
  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
end
