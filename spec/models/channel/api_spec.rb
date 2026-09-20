# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Channel::Api do
  # This validation happens in ApplicationRecord
  describe 'length validations' do
    let(:channel_api) { create(:channel_api) }

    context 'when it validates webhook_url length' do
      it 'valid when within limit' do
        channel_api.webhook_url = 'a' * Limits::URL_LENGTH_LIMIT
        expect(channel_api.valid?).to be true
      end

      it 'invalid when crossed the limit' do
        channel_api.webhook_url = 'a' * (Limits::URL_LENGTH_LIMIT + 1)
        channel_api.valid?
        expect(channel_api.errors[:webhook_url]).to include("is too long (maximum is #{Limits::URL_LENGTH_LIMIT} characters)")
      end
    end
  end

  describe 'blank webhook_url normalization' do
    let(:channel_api) { create(:channel_api) }

    it 'stores nil when the dashboard sends the JS string "null"' do
      channel_api.update!(webhook_url: 'null')
      expect(channel_api.reload.webhook_url).to be_nil
    end

    it 'stores nil for "undefined" and whitespace' do
      channel_api.update!(webhook_url: 'undefined')
      expect(channel_api.reload.webhook_url).to be_nil

      channel_api.update!(webhook_url: '   ')
      expect(channel_api.reload.webhook_url).to be_nil
    end

    it 'keeps a real URL untouched' do
      channel_api.update!(webhook_url: 'https://example.com/hook')
      expect(channel_api.reload.webhook_url).to eq('https://example.com/hook')
    end
  end
end
