# frozen_string_literal: true

require 'legion/extensions/identity/aws/version'
require 'legion/extensions/identity/aws/settings'
require 'legion/extensions/identity/aws/identity'

module Legion
  module Extensions
    module Identity
      module Aws
        extend Legion::Extensions::Core if Legion::Extensions.const_defined?(:Core, false)

        def self.identity_provider?
          true
        end

        def self.remote_invocable?
          false
        end

        def self.provider_name
          Identity.provider_name
        end

        def self.provider_type
          Identity.provider_type
        end

        def self.facing
          Identity.facing
        end
      end
    end
  end
end
