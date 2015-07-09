# Dispatches a webhook to the given url
class SendWebhookJob
  include Sidekiq::Worker

  def perform(webhook_url)
    Faraday.post(webhook_url) do |req|
      req.body = countries_json
      req.headers['Content-Type'] = 'application/json'
    end
  end

  def countries_json
    open('https://raw.githubusercontent.com/everypolitician/everypolitician-data/master/countries.json').read
  end
end
