require 'bundler'
Bundler.require
Dotenv.load

require 'openssl'
require 'json'

# Mixin to provide a GitHub client.
module Github
  def github
    @github ||= Octokit::Client.new(access_token: ENV['GITHUB_ACCESS_TOKEN'])
  end
end

# Background job that merges pull requests.
class MergeJob
  include Sidekiq::Worker
  include Github

  def perform(repo, number)
    github.merge_pull_request(repo, number)
  end
end

configure do
  set :github_webhook_secret, ENV['GITHUB_WEBHOOK_SECRET']
end

helpers do
  HMAC_DIGEST = OpenSSL::Digest.new('sha1')

  # Taken from https://developer.github.com/webhooks/securing/
  def verify_signature(payload_body)
    signature = 'sha1=' + OpenSSL::HMAC.hexdigest(
      HMAC_DIGEST,
      settings.github_webhook_secret,
      payload_body
    )
    signatures_match = Rack::Utils.secure_compare(
      signature,
      request.env['HTTP_X_HUB_SIGNATURE']
    )
    return halt 500, "Signatures didn't match!" unless signatures_match
  end
end

post '/github_events' do
  request.body.rewind
  payload_body = request.body.read
  verify_signature(payload_body)
  pull_request = JSON.parse(payload_body)
  type = request.env['HTTP_X_GITHUB_EVENT']
  action = pull_request['action']
  user = pull_request['pull_request']['user']['login']
  if type == 'pull_request' && action == 'opened' &&
     user == 'seepoliticianstweetbot'
    repo = pull_request['repository']['full_name']
    number = pull_request['number']
    MergeJob.perform_async(repo, number)
  end
  'OK'
end
