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

  def perform(webhook_url, action, pull_request_number, pull_request_head)
    Faraday.post(webhook_url) do |req|
      req.body = webhook_body(pull_request_number, pull_request_head).to_json
      req.headers['Content-Type'] = 'application/json'
      req.headers['X-EveryPolitician-Event'] = action
      req.options.timeout = 10
      req.options.open_timeout = 5
    end
  end

  def webhook_body(pull_request_number, pull_request_head)
    {
      countries_json_url: "https://cdn.rawgit.com/everypolitician/everypolitician-data/#{pull_request_head}/countries.json",
      pull_request_url: "https://api.github.com/repos/everypolitician/everypolitician-data/pulls/#{pull_request_number}"
    }
  end
end
