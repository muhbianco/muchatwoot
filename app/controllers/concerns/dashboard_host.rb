# Hosts próprios de cliente (ex.: chatwoot.cliente.com.br) atendem uma account só.
# A lista fica em accounts.custom_attributes['dashboard_hosts'], gravada pela Platform API;
# o admin da account não altera essa chave. Host que não é de cliente (o principal, chamadas
# internas) não restringe nada.
module DashboardHost
  private

  def dashboard_host_account_id
    return @dashboard_host_account_id if defined?(@dashboard_host_account_id)

    host = request.host.to_s.downcase
    @dashboard_host_account_id = Rails.cache.fetch("dashboard_host/#{host}", expires_in: 1.minute) do
      Account.where("custom_attributes -> 'dashboard_hosts' @> ?", [host].to_json).pick(:id)
    end
  end

  def dashboard_host_allows_account?(account_id)
    dashboard_host_account_id.nil? || dashboard_host_account_id == account_id
  end

  def dashboard_host_allows_user?(user)
    dashboard_host_account_id.nil? || user.account_users.exists?(account_id: dashboard_host_account_id)
  end

  # Login (DeviseOverrides::SessionsController): credencial certa, host de outro cliente.
  # Desfaz o token recém-criado e responde como senha errada; @resource = nil faz o
  # after_action do devise_token_auth não devolver cabeçalhos de auth.
  def reject_login_outside_dashboard_host
    @resource.tokens.delete(@token.client) if @token
    @resource.save!
    @resource = nil
    render_error(:unauthorized, I18n.t('devise_token_auth.sessions.bad_credentials'))
  end
end
