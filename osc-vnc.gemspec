# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'osc/vnc/version'

Gem::Specification.new do |spec|
  spec.name          = "osc-vnc"
  spec.version       = OSC::VNC::VERSION
  spec.platform      = Gem::Platform::RUBY
  spec.authors       = ["Jeremy Nicklas"]
  spec.email         = ["jnicklas@osc.edu"]
  spec.summary       = %q{Library to create VNC jobs with HPC resources (OSC specific)}
  spec.description   = %q{This library submits VNC jobs to the Oxymoron cluster as well as obtains the connection information required for a connection to take place with a VNC client. (OSC specific)}
  spec.homepage      = "https://github.com/OSC/osc-vnc"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "pbs", "~> 2.0", ">= 2.0.3"
  spec.add_runtime_dependency "mustache", "~> 1.0"
  spec.add_development_dependency "bundler", "~> 1.7"
  spec.add_development_dependency "rake", "~> 10.0"
end
