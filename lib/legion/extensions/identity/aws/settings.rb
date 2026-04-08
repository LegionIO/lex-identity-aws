# frozen_string_literal: true

module Legion
  module Extensions
    module Identity
      module Aws
        SETTINGS_DEFAULTS = {
          region:           nil,
          role_arn:         nil,
          session_duration: 3600,
          profile:          nil
        }.freeze

        def self.settings
          base = if defined?(Legion::Settings) && Legion::Settings.respond_to?(:dig)
                   Legion::Settings.dig(:identity, :aws) || {}
                 else
                   {}
                 end

          region = ENV.fetch('AWS_REGION', nil) || ENV.fetch('AWS_DEFAULT_REGION', nil) || 'us-east-2'
          role_arn = ENV.fetch('AWS_ROLE_ARN', nil)
          profile  = ENV.fetch('AWS_PROFILE', nil)

          SETTINGS_DEFAULTS
            .merge(region: region, role_arn: role_arn, profile: profile)
            .merge(base)
        end
      end
    end
  end
end
