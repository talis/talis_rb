# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'talis/version'

# rubocop:disable Metrics/LineLength
Gem::Specification.new do |spec|
  spec.name          = 'talis'
  spec.version       = Talis::VERSION
  spec.authors       = ['Omar Qureshi', 'Ben Paddock']
  spec.email         = ['oq@talis.com', 'bp@talis.com']

  spec.summary       = 'Ruby client to utilise Talis primitive services'
  spec.homepage      = 'https://github.com/talis/talis_rb'

  # Prevent pushing this gem to RubyGems.org by setting 'allowed_push_host', or
  # delete this section to allow pushing this gem to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = 'TODO: Set to "http://mygemserver.com"'
  else
    raise 'RubyGems 2.0 or newer is required to protect against public gem pushes.'
  end

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'uuid', '2.3.8'
  spec.add_dependency 'jwt', '1.5.4'
  spec.add_dependency 'activesupport', '~> 4.2.6'
  spec.add_dependency 'httparty', '0.13.7'
  spec.add_dependency 'multi_json', '1.11.2'
  spec.add_dependency 'blueprint_ruby_client', '~> 0.5.1'
  spec.add_dependency 'metatron_ruby_client', '~> 0.1.3'

  spec.add_development_dependency 'cucumber'
  spec.add_development_dependency 'dotenv'
  spec.add_development_dependency 'bundler', '~> 1.11'
  spec.add_development_dependency 'guard'
  spec.add_development_dependency 'guard-rspec'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'rubocop', '~> 0.39.0'
  spec.add_development_dependency 'webmock', '~> 1.24.2'
end
