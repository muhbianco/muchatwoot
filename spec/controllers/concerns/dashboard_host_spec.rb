require 'rails_helper'

RSpec.describe 'Dashboard host scope', type: :request do
  let(:host) { 'chatwoot.cliente.test' }
  let(:account) { create(:account, custom_attributes: { 'dashboard_hosts' => [host] }) }
  let(:other_account) { create(:account) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let(:outsider) { create(:user, account: other_account, role: :agent) }

  describe 'account APIs' do
    it 'serves the account that owns the host' do
      host! host
      get "/api/v1/accounts/#{account.id}/inboxes", headers: agent.create_new_auth_token, as: :json

      expect(response).to have_http_status(:success)
    end

    it 'refuses another account on a customer host' do
      host! host
      get "/api/v1/accounts/#{other_account.id}/inboxes", headers: outsider.create_new_auth_token, as: :json

      expect(response).to have_http_status(:unauthorized)
    end

    it 'does not restrict hosts that belong to no account' do
      get "/api/v1/accounts/#{other_account.id}/inboxes", headers: outsider.create_new_auth_token, as: :json

      expect(response).to have_http_status(:success)
    end
  end

  describe 'login' do
    let(:password) { 'Test@123456' }

    it 'accepts a user of the account that owns the host' do
      agent.update!(password: password, password_confirmation: password)
      host! host
      post '/auth/sign_in', params: { email: agent.email, password: password }, as: :json

      expect(response).to have_http_status(:success)
    end

    it 'rejects a user of another account and keeps no token for them' do
      outsider.update!(password: password, password_confirmation: password)
      host! host
      post '/auth/sign_in', params: { email: outsider.email, password: password }, as: :json

      expect(response).to have_http_status(:unauthorized)
      expect(response.headers['access-token']).to be_nil
      expect(outsider.reload.tokens).to be_blank
    end
  end
end
