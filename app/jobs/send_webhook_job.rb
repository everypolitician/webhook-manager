# Dispatches a webhook to the given url
class SendWebhookJob
  include Sidekiq::Worker

  def perform(webhook_url)
    Faraday.post(webhook_url)
  end
end
