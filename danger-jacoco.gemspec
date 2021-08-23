# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'jacoco/gem_version'

Gem::Specification.new do |spec|
  spec.name          = 'danger-jacoco'
  spec.version       = Jacoco::VERSION
  spec.authors       = ['Anton Malinskiy']
  spec.email         = ['anton@malinskiy.com']
  spec.description   = 'A short description of danger-jacoco.'
  spec.summary       = 'A longer description of danger-jacoco.'
  spec.homepage      = 'https://github.com/Malinskiy/danger-jacoco'
  spec.license       = 'MIT'

  spec.files         = `git ls-files`.split($INPUT_RECORD_SEPARATOR)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']
  spec.required_ruby_version = '>= 2.6'

  spec.add_runtime_dependency 'danger-plugin-api', '~> 1.0'
  spec.add_runtime_dependency 'nokogiri-happymapper', '~> 0.6'

  # General ruby development
  spec.add_development_dependency 'bundler', '~> 2.0'
  spec.add_development_dependency 'rake', '~> 13.0'

  # Testing support
  spec.add_development_dependency 'rspec', '~> 3.7'

  # Linting code and docs
  spec.add_development_dependency 'rubocop', '~> 1.14'
  spec.add_development_dependency 'yard', '~> 0.9'

  # Makes testing easy via `bundle exec guard`
  spec.add_development_dependency 'guard', '~> 2.14'
  spec.add_development_dependency 'guard-rspec', '~> 4.7'

  # If you want to work on older builds of ruby
  spec.add_development_dependency 'listen', '3.7.0'

  # This gives you the chance to run a REPL inside your tests
  # via:
  #
  #    require 'pry'
  #    binding.pry
  #
  # This will stop test execution and let you inspect the results
  spec.add_development_dependency 'pry'
end
