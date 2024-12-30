# frozen_string_literal: true

# Copyright (c) Steven Hoffman
# All rights reserved.

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'unary_plus/version'

::Gem::Specification.new do |spec|
  spec.name = 'unary_plus'
  spec.version = ::UnaryPlus::VERSION
  spec.authors = ['Steven Hoffman']
  spec.required_ruby_version = '>= 3.4.1'
  spec.metadata['rubygems_mfa_required'] = 'true'

  spec.summary = 'A few useful services and initializers.'
  spec.homepage = 'https://github.com/fustrate/fustrate-rails'
  spec.license = 'MIT'

  spec.files = ::Dir['{config,lib}/**/*']
  spec.executables = []
  spec.require_paths = ['lib']

  spec.add_dependency 'activesupport', '>= 8.0'
  spec.add_dependency 'jbuilder', '~> 2.11'
  spec.add_dependency 'railties', '>= 7.2'
  spec.add_dependency 'sanitize', '~> 7.0'
  spec.add_dependency 'zeitwerk', '~> 2.6'
end
