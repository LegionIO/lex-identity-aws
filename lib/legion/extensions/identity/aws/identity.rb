# frozen_string_literal: true

module Legion
  module Extensions
    module Identity
      module Aws
        module Identity
          def self.provider_name
            :aws
          end

          def self.provider_type
            :auth
          end

          def self.facing
            :machine
          end

          def self.priority
            90
          end

          def self.trust_weight
            100
          end

          def self.capabilities
            %i[authenticate credentials]
          end

          def self.resolve(canonical_name: nil) # rubocop:disable Lint/UnusedMethodArgument
            identity = caller_identity
            return nil unless identity

            # ARN format: arn:aws:sts::123456789012:assumed-role/role-name/session-name
            # or:         arn:aws:iam::123456789012:role/role-name
            arn_parts = identity.arn.to_s.split('/')
            role_name = arn_parts[1] || identity.arn.to_s.split(':').last

            {
              canonical_name: normalize(role_name),
              kind:           :machine,
              source:         :aws,
              persistent:     true,
              groups:         [],
              metadata:       {
                account_id: identity.account,
                arn:        identity.arn,
                user_id:    identity.user_id
              }
            }
          end

          def self.provide_token
            credentials = resolve_credentials
            return nil unless credentials

            expires_at = if credentials.respond_to?(:expiration) && credentials.expiration
                           credentials.expiration
                         else
                           Time.now + 3600
                         end

            # Store the full credential object for Broker.credentials_for(:aws) consumers.
            # NEVER store secret_access_key or session_token in Lease metadata —
            # Lease#to_h is exposed via audit logs, /api/stats, and Apollo.
            @credential_cache = credentials # rubocop:disable ThreadSafety/ClassInstanceVariable

            Legion::Identity::Lease.new(
              provider:   :aws,
              credential: credentials.access_key_id,
              expires_at: expires_at,
              renewable:  credentials.respond_to?(:expiration),
              issued_at:  Time.now,
              metadata:   {
                access_key_id: credentials.access_key_id,
                region:        settings[:region],
                expiration:    expires_at&.iso8601
              }
            )
          end

          def self.current_credentials
            @credential_cache # rubocop:disable ThreadSafety/ClassInstanceVariable
          end

          def self.normalize(val)
            val.to_s.downcase.strip.gsub(/[^a-z0-9_-]/, '_')
          end

          def self.settings
            Legion::Extensions::Identity::Aws.settings
          end

          def self.caller_identity
            require 'aws-sdk-sts'
            sts = ::Aws::STS::Client.new(region: settings[:region])
            sts.get_caller_identity
          rescue ::Aws::Errors::ServiceError => e
            Legion::Logging.warn("AWS STS get_caller_identity failed: #{e.message}")
            nil
          end

          def self.resolve_credentials
            if settings[:role_arn]
              assume_role_credentials
            else
              default_chain_credentials
            end
          end

          def self.assume_role_credentials
            require 'aws-sdk-sts'
            instance_id = defined?(Legion) && Legion.respond_to?(:instance_id) ? Legion.instance_id.to_s[0..7] : 'default'
            ::Aws::AssumeRoleCredentials.new(
              client:            ::Aws::STS::Client.new(region: settings[:region]),
              role_arn:          settings[:role_arn],
              role_session_name: "legion-#{instance_id}",
              duration_seconds:  settings[:session_duration] || 3600
            )
          rescue ::Aws::Errors::ServiceError => e
            Legion::Logging.warn("AWS AssumeRole failed: #{e.message}")
            nil
          end

          def self.default_chain_credentials
            require 'aws-sdk-core'
            # Use an STS client to trigger the full SDK default credential chain.
            # Aws::CredentialProviderChain is internal and not a public API.
            # Creating an STS client triggers: env vars -> shared credentials ->
            # web identity -> ECS task role -> instance profile (the full chain).
            client = ::Aws::STS::Client.new(region: settings[:region])
            creds  = client.config.credentials
            creds.credentials # force-resolve lazy credentials
            creds
          rescue StandardError => e
            # Aws::EC2Metadata::RequestError is RuntimeError, not ServiceError.
            # Aws::Errors::NoSuchProfileError for invalid AWS_PROFILE.
            # All caught here for graceful fallback.
            Legion::Logging.debug("AWS default chain failed: #{e.message}")
            nil
          end

          private_class_method :caller_identity, :resolve_credentials, :assume_role_credentials,
                               :default_chain_credentials, :settings
        end
      end
    end
  end
end
