# Dispatches a webhook to the given url
class SendWebhookJob
  include Sidekiq::Worker

  # Discard the job immediately if it fails.
  #
  # FIXME: This is OK for the webhook for all countries because that usually
  # gets triggered multiple times per day. When we add webhooks for individual
  # countries we should then consider adding some kind of retry mechanism as
  # these won't be delivered as frequently.
  sidekiq_options retry: false

  def perform(webhook_url)
    Faraday.post(webhook_url) do |req|
      req.body = countries_json
      req.headers['Content-Type'] = 'application/json'
      req.options.timeout = 10
      req.options.open_timeout = 5
    end
  end

  def countries_json
    open('https://raw.githubusercontent.com/everypolitician/everypolitician-data/master/countries.json').read
  end
end
