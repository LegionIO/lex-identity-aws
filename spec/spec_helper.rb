# frozen_string_literal: true

require 'simplecov'
SimpleCov.start do
  add_filter '/spec/'
end

require 'bundler/setup'

# Minimal Legion stubs — avoids requiring the full framework in unit tests
module Legion
  module Extensions
    module Helpers
      module Lex; end
    end
  end

  module Logging
    def self.warn(msg); end
    def self.info(msg); end
    def self.debug(msg); end
  end

  module Settings
    def self.[](_key)
      nil
    end

    def self.dig(*_keys)
      nil
    end

    def self.merge_settings(_key, _defaults); end
  end

  module JSON
    def self.dump(obj)
      require 'json'
      ::JSON.generate(obj)
    end

    def self.load(str)
      require 'json'
      ::JSON.parse(str, symbolize_names: true)
    end
  end

  module Identity
    class Lease
      attr_reader :provider, :credential, :expires_at, :renewable, :issued_at, :metadata, :lease_id

      def initialize(provider:, credential:, expires_at:, renewable:, issued_at:, metadata: {}, lease_id: nil)
        @provider   = provider
        @credential = credential
        @expires_at = expires_at
        @renewable  = renewable
        @issued_at  = issued_at
        @metadata   = metadata
        @lease_id   = lease_id
      end

      def valid?
        expires_at.nil? || expires_at > Time.now
      end
    end
  end
end

require 'legion/extensions/identity/aws'

RSpec.configure do |config|
  config.example_status_persistence_file_path = '.rspec_status'
  config.disable_monkey_patching!
  config.expect_with(:rspec) { |c| c.syntax = :expect }
end
