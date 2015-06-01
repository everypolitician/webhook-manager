require 'bundler'
Bundler.require
Dotenv.load

require 'json'

$LOAD_PATH << File.expand_path('../lib', __FILE__)
$LOAD_PATH << File.expand_path('../', __FILE__)

require 'helpers'
require 'app/jobs'

configure do
  set :github_webhook_secret, ENV['GITHUB_WEBHOOK_SECRET']
end

helpers Helpers

get '/' do
  content_type 'application/json'
  JSON.pretty_generate(
    webhook_receivers: {
      pull_requests: url('/new-pull-request'),
      pushes: url('/everypolitician-data-push')
    }
  )
end

post '/new-pull-request' do
  type = request.env['HTTP_X_GITHUB_EVENT']
  if type == 'pull_request'
    pull_request = JSON.parse(payload_body)
    MergeJob.perform_async(pull_request)
  end
  'OK'
end

# Check for new countries
post '/everypolitician-data-push' do
  type = request.env['HTTP_X_GITHUB_EVENT']
  if type == 'push'
    push = JSON.parse(payload_body)
    UpdateViewerSinatraJob.perform_async(push)
  end
  'OK'
end
