# frozen_string_literal: true

require_relative 'lib/legion/extensions/identity/aws/version'

Gem::Specification.new do |spec|
  spec.name          = 'lex-identity-aws'
  spec.version       = Legion::Extensions::Identity::Aws::VERSION
  spec.authors       = ['Esity']
  spec.email         = ['matthewdiverson@gmail.com']

  spec.summary       = 'LEX Identity AWS'
  spec.description   = 'LegionIO AWS IAM identity provider — resolves machine identity from STS ' \
                       'and provides session credentials via instance profile or AssumeRole'
  spec.homepage      = 'https://github.com/LegionIO/lex-identity-aws'
  spec.license       = 'MIT'
  spec.required_ruby_version = '>= 3.4'

  spec.metadata['homepage_uri']          = spec.homepage
  spec.metadata['source_code_uri']       = 'https://github.com/LegionIO/lex-identity-aws'
  spec.metadata['documentation_uri']     = 'https://github.com/LegionIO/lex-identity-aws'
  spec.metadata['changelog_uri']         = 'https://github.com/LegionIO/lex-identity-aws'
  spec.metadata['bug_tracker_uri']       = 'https://github.com/LegionIO/lex-identity-aws/issues'
  spec.metadata['rubygems_mfa_required'] = 'true'

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.require_paths = ['lib']

  spec.add_dependency 'aws-sdk-core', '>= 3.0'
  spec.add_dependency 'aws-sdk-sts',  '>= 1.0'
  spec.add_dependency 'legion-json',     '>= 1.2.1'
  spec.add_dependency 'legion-settings', '>= 1.3.14'
end
