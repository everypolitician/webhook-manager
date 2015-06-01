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

post '/github_events' do
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

# Check for new countries
post '/everypolitician-data-push' do
  type = request.env['HTTP_X_GITHUB_EVENT']
  if type == 'push'
    push = JSON.parse(payload_body)
    UpdateViewerSinatraJob.perform_async(push)
  end
  'OK'
end
