class WebhookJob < ApplicationJob
  queue_as :medium
  #  There are 3 types of webhooks, account, inbox and agent_bot
  def perform(url, payload, webhook_type = :account_webhook, secret: nil, delivery_id: nil)
    href = url.to_s.strip
    unless href.match?(%r{\Ahttps?://}i)
      Rails.logger.info("WebhookJob skipped invalid url type=#{webhook_type}")
      return
    end
    Webhooks::Trigger.execute(url, payload, webhook_type, secret: secret, delivery_id: delivery_id)
  end
end
