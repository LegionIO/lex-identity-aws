# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Legion::Extensions::Identity::Aws do
  describe '.settings' do
    subject(:settings) { described_class.settings }

    context 'with no ENV vars set' do
      before do
        allow(ENV).to receive(:fetch).with('AWS_REGION', nil).and_return(nil)
        allow(ENV).to receive(:fetch).with('AWS_DEFAULT_REGION', nil).and_return(nil)
        allow(ENV).to receive(:fetch).with('AWS_ROLE_ARN', nil).and_return(nil)
        allow(ENV).to receive(:fetch).with('AWS_PROFILE', nil).and_return(nil)
      end

      it 'defaults region to us-east-2' do
        expect(settings[:region]).to eq('us-east-2')
      end

      it 'defaults role_arn to nil' do
        expect(settings[:role_arn]).to be_nil
      end

      it 'defaults session_duration to 3600' do
        expect(settings[:session_duration]).to eq(3600)
      end

      it 'defaults profile to nil' do
        expect(settings[:profile]).to be_nil
      end
    end

    context 'with AWS_REGION set' do
      before do
        allow(ENV).to receive(:fetch).with('AWS_REGION', nil).and_return('us-west-2')
        allow(ENV).to receive(:fetch).with('AWS_DEFAULT_REGION', nil).and_return(nil)
        allow(ENV).to receive(:fetch).with('AWS_ROLE_ARN', nil).and_return(nil)
        allow(ENV).to receive(:fetch).with('AWS_PROFILE', nil).and_return(nil)
      end

      it 'uses AWS_REGION' do
        expect(settings[:region]).to eq('us-west-2')
      end
    end

    context 'with AWS_DEFAULT_REGION set but not AWS_REGION' do
      before do
        allow(ENV).to receive(:fetch).with('AWS_REGION', nil).and_return(nil)
        allow(ENV).to receive(:fetch).with('AWS_DEFAULT_REGION', nil).and_return('eu-west-1')
        allow(ENV).to receive(:fetch).with('AWS_ROLE_ARN', nil).and_return(nil)
        allow(ENV).to receive(:fetch).with('AWS_PROFILE', nil).and_return(nil)
      end

      it 'falls back to AWS_DEFAULT_REGION' do
        expect(settings[:region]).to eq('eu-west-1')
      end
    end

    context 'with AWS_ROLE_ARN set' do
      let(:arn) { 'arn:aws:iam::123456789012:role/my-role' }

      before do
        allow(ENV).to receive(:fetch).with('AWS_REGION', nil).and_return(nil)
        allow(ENV).to receive(:fetch).with('AWS_DEFAULT_REGION', nil).and_return(nil)
        allow(ENV).to receive(:fetch).with('AWS_ROLE_ARN', nil).and_return(arn)
        allow(ENV).to receive(:fetch).with('AWS_PROFILE', nil).and_return(nil)
      end

      it 'captures role_arn' do
        expect(settings[:role_arn]).to eq(arn)
      end
    end

    context 'with AWS_PROFILE set' do
      before do
        allow(ENV).to receive(:fetch).with('AWS_REGION', nil).and_return(nil)
        allow(ENV).to receive(:fetch).with('AWS_DEFAULT_REGION', nil).and_return(nil)
        allow(ENV).to receive(:fetch).with('AWS_ROLE_ARN', nil).and_return(nil)
        allow(ENV).to receive(:fetch).with('AWS_PROFILE', nil).and_return('vault-contributor')
      end

      it 'captures profile' do
        expect(settings[:profile]).to eq('vault-contributor')
      end
    end
  end
end
