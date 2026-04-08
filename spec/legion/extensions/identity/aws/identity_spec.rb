# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Legion::Extensions::Identity::Aws::Identity do
  subject(:identity) { described_class }

  # --- provider contract interface ---

  describe '.provider_name' do
    it 'returns :aws' do
      expect(identity.provider_name).to eq(:aws)
    end
  end

  describe '.provider_type' do
    it 'returns :auth' do
      expect(identity.provider_type).to eq(:auth)
    end
  end

  describe '.facing' do
    it 'returns :machine' do
      expect(identity.facing).to eq(:machine)
    end
  end

  describe '.priority' do
    it 'returns 90' do
      expect(identity.priority).to eq(90)
    end
  end

  describe '.trust_weight' do
    it 'returns 100' do
      expect(identity.trust_weight).to eq(100)
    end
  end

  describe '.capabilities' do
    it 'includes :authenticate' do
      expect(identity.capabilities).to include(:authenticate)
    end

    it 'includes :credentials' do
      expect(identity.capabilities).to include(:credentials)
    end
  end

  # --- normalize ---

  describe '.normalize' do
    it 'lowercases the value' do
      expect(identity.normalize('MyRole')).to eq('myrole')
    end

    it 'strips leading and trailing whitespace' do
      expect(identity.normalize('  role  ')).to eq('role')
    end

    it 'replaces special characters with underscores' do
      expect(identity.normalize('my-role/session')).to eq('my-role_session')
    end

    it 'preserves hyphens' do
      expect(identity.normalize('my-role')).to eq('my-role')
    end

    it 'preserves underscores' do
      expect(identity.normalize('my_role')).to eq('my_role')
    end

    it 'preserves digits' do
      expect(identity.normalize('role42')).to eq('role42')
    end

    it 'handles an empty string' do
      expect(identity.normalize('')).to eq('')
    end

    it 'handles nil by converting to empty string' do
      expect(identity.normalize(nil)).to eq('')
    end
  end

  # --- resolve ---

  describe '.resolve' do
    let(:sts_response) do
      instance_double('Aws::STS::Types::GetCallerIdentityResponse',
                      arn:     'arn:aws:sts::123456789012:assumed-role/legion-worker/session',
                      account: '123456789012',
                      user_id: 'AROAEXAMPLEID:session')
    end

    context 'when STS returns a valid caller identity' do
      before do
        allow(identity).to receive(:caller_identity).and_return(sts_response)
      end

      it 'returns a hash' do
        expect(identity.resolve).to be_a(Hash)
      end

      it 'sets kind to :machine' do
        expect(identity.resolve[:kind]).to eq(:machine)
      end

      it 'sets source to :aws' do
        expect(identity.resolve[:source]).to eq(:aws)
      end

      it 'sets persistent to true' do
        expect(identity.resolve[:persistent]).to be true
      end

      it 'sets groups to an empty array' do
        expect(identity.resolve[:groups]).to eq([])
      end

      it 'derives canonical_name from the ARN role name segment' do
        expect(identity.resolve[:canonical_name]).to eq('legion-worker')
      end

      it 'includes account_id in metadata' do
        expect(identity.resolve[:metadata][:account_id]).to eq('123456789012')
      end

      it 'includes arn in metadata' do
        expect(identity.resolve[:metadata][:arn]).to eq('arn:aws:sts::123456789012:assumed-role/legion-worker/session')
      end

      it 'includes user_id in metadata' do
        expect(identity.resolve[:metadata][:user_id]).to eq('AROAEXAMPLEID:session')
      end
    end

    context 'when ARN is a plain IAM role (no slash segments after role name)' do
      let(:iam_response) do
        instance_double('Aws::STS::Types::GetCallerIdentityResponse',
                        arn:     'arn:aws:iam::123456789012:role/my-role',
                        account: '123456789012',
                        user_id: 'AROAEXAMPLEID')
      end

      before do
        allow(identity).to receive(:caller_identity).and_return(iam_response)
      end

      it 'uses the ARN role name as canonical_name' do
        expect(identity.resolve[:canonical_name]).to eq('my-role')
      end
    end

    context 'when STS raises an error' do
      before do
        allow(identity).to receive(:caller_identity).and_return(nil)
      end

      it 'returns nil' do
        expect(identity.resolve).to be_nil
      end
    end
  end

  # --- provide_token ---

  describe '.provide_token' do
    let(:mock_credentials) do
      instance_double('Aws::Credentials',
                      access_key_id:     'AKIAEXAMPLE',
                      secret_access_key: 'secret-should-not-appear',
                      session_token:     'token-should-not-appear',
                      expiration:        Time.now + 3600)
    end

    context 'when credentials are resolved successfully' do
      before do
        allow(identity).to receive(:resolve_credentials).and_return(mock_credentials)
        allow(mock_credentials).to receive(:respond_to?).with(:expiration).and_return(true)
      end

      it 'returns a Lease' do
        expect(identity.provide_token).to be_a(Legion::Identity::Lease)
      end

      it 'sets provider to :aws' do
        expect(identity.provide_token.provider).to eq(:aws)
      end

      it 'sets credential to access_key_id only' do
        expect(identity.provide_token.credential).to eq('AKIAEXAMPLE')
      end

      it 'sets issued_at' do
        expect(identity.provide_token.issued_at).not_to be_nil
      end

      it 'sets expires_at from credential expiration' do
        expect(identity.provide_token.expires_at).not_to be_nil
      end

      it 'does NOT store secret_access_key in metadata' do
        metadata = identity.provide_token.metadata
        expect(metadata.to_s).not_to include('secret-should-not-appear')
      end

      it 'does NOT store session_token in metadata' do
        metadata = identity.provide_token.metadata
        expect(metadata.to_s).not_to include('token-should-not-appear')
      end

      it 'stores access_key_id in metadata' do
        expect(identity.provide_token.metadata[:access_key_id]).to eq('AKIAEXAMPLE')
      end

      it 'stores region in metadata' do
        expect(identity.provide_token.metadata).to have_key(:region)
      end

      it 'stores expiration as iso8601 string in metadata' do
        expect(identity.provide_token.metadata[:expiration]).to be_a(String)
      end
    end

    context 'when credentials are nil (no AWS credentials available)' do
      before do
        allow(identity).to receive(:resolve_credentials).and_return(nil)
      end

      it 'returns nil' do
        expect(identity.provide_token).to be_nil
      end
    end

    context 'when credentials have no expiration (static creds)' do
      let(:static_creds) do
        instance_double('Aws::Credentials',
                        access_key_id:     'AKIASTATIC',
                        secret_access_key: 'secret',
                        session_token:     nil,
                        expiration:        nil)
      end

      before do
        allow(identity).to receive(:resolve_credentials).and_return(static_creds)
        allow(static_creds).to receive(:respond_to?).with(:expiration).and_return(false)
      end

      it 'defaults expires_at to 1 hour from now' do
        lease = identity.provide_token
        expect(lease.expires_at).to be_within(5).of(Time.now + 3600)
      end

      it 'sets renewable to false for static credentials' do
        expect(identity.provide_token.renewable).to be false
      end
    end
  end

  # --- current_credentials ---

  describe '.current_credentials' do
    let(:mock_credentials) do
      instance_double('Aws::Credentials',
                      access_key_id: 'AKIAEXAMPLE',
                      expiration:    Time.now + 3600)
    end

    before do
      allow(identity).to receive(:resolve_credentials).and_return(mock_credentials)
      allow(mock_credentials).to receive(:respond_to?).with(:expiration).and_return(true)
      identity.provide_token
    end

    it 'returns the cached credential object after provide_token is called' do
      expect(identity.current_credentials).to eq(mock_credentials)
    end
  end

  # --- top-level module contract ---

  describe 'Legion::Extensions::Identity::Aws' do
    subject(:mod) { Legion::Extensions::Identity::Aws }

    it 'declares itself as an identity provider' do
      expect(mod.identity_provider?).to be true
    end

    it 'is not remote invocable' do
      expect(mod.remote_invocable?).to be false
    end

    it 'delegates provider_name to Identity' do
      expect(mod.provider_name).to eq(:aws)
    end

    it 'delegates provider_type to Identity' do
      expect(mod.provider_type).to eq(:auth)
    end

    it 'delegates facing to Identity' do
      expect(mod.facing).to eq(:machine)
    end
  end
end
