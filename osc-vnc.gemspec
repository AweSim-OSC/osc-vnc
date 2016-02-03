# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'osc/vnc/version'

Gem::Specification.new do |spec|
  spec.name          = "osc-vnc"
  spec.version       = OSC::VNC::VERSION
  spec.authors       = ["Jeremy Nicklas"]
  spec.email         = ["jnicklas@osc.edu"]
  spec.description   = %q{Library to create VNC jobs with HPC resources}
  spec.summary       = %q{This library submits VNC jobs to the Oxymoron cluster as well as obtains the connection information required for a connection to take place with a VNC client.}
  spec.homepage      = "http://www.awesim.org"
  # spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "pbs", "~> 1.0"
  spec.add_runtime_dependency "mustache", "~> 0.99", ">= 0.99.5"
  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
end
