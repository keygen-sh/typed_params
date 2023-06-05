require_relative 'lib/typed_parameters/version'

Gem::Specification.new do |spec|
  spec.name        = 'typed_parameters'
  spec.version     = TypedParameters::VERSION
  spec.authors     = ['Zeke Gabrielse']
  spec.email       = ['oss@keygen.sh']
  spec.summary     = 'Define structured and strongly-typed parameter schemas for your Rails controllers.'
  spec.description = 'Typed parameters is an alternative to strong parameters, offering an intuitive DSL for defining structured and strongly-typed controller parameter schemas.'
  spec.homepage    = 'https://github.com/keygen-sh/typed_parameters'
  spec.license     = 'MIT'

  spec.required_ruby_version = '>= 3.1'
  spec.files                 = %w[LICENSE CHANGELOG.md CONTRIBUTING.md SECURITY.md README.md] + Dir.glob('lib/**/*')
  spec.require_paths         = ['lib']

  spec.add_dependency 'rails', '>= 6.0'

  spec.add_development_dependency 'rspec-rails'
end
