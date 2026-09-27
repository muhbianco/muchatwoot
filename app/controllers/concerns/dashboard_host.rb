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
end
