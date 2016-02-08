require 'openssl'

# Dispatches a webhook to the given url
class SendWebhookJob
  HMAC_DIGEST = OpenSSL::Digest.new('sha1')

  include Sidekiq::Worker

  # Discard the job if it fails 3 times.
  sidekiq_options retry: 3

  def perform(application_id, action, pull_request_number, pull_request_head)
    application = Application[application_id]
    Faraday.post(application.webhook_url) do |req|
      req.body = webhook_body(pull_request_number, pull_request_head).to_json
      if application.secret && !application.secret.empty?
        req.headers['X-EveryPolitician-Signature'] =
          'sha1='+OpenSSL::HMAC.hexdigest(HMAC_DIGEST, application.secret, req.body)
      end
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
