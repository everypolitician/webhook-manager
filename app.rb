require 'bundler'
Bundler.require
Dotenv.load

require 'json'

$LOAD_PATH << File.expand_path('../lib', __FILE__)
$LOAD_PATH << File.expand_path('../', __FILE__)

require 'helpers'
require 'app/models'
require 'app/jobs'

configure do
  enable :sessions
  set :session_secret, ENV['SESSION_SECRET']
  set :database, DB
  set :github_webhook_secret, ENV['GITHUB_WEBHOOK_SECRET']
end

helpers Helpers

use OmniAuth::Builder do
  provider :github, ENV['GITHUB_KEY'], ENV['GITHUB_SECRET'], scope: 'user:email'
end

use Rack::Flash

get '/' do
  erb :index
end

get '/auth/github/callback' do
  auth = request.env['omniauth.auth']
  user = User.first(github_uid: auth[:uid])
  if user
    session[:user_id] = user.id
  else
    session[:user_id] = User.insert(
      name: auth[:info][:name],
      email: auth[:info][:email],
      github_uid: auth[:uid],
      github_token: auth[:credentials][:token]
    )
  end
  flash[:notice] = 'You have successfully logged in with Twitter'
  redirect to('/')
end

get '/logout' do
  session.clear
  flash[:notice] = 'You have been logged out'
  redirect to('/')
end

get '/urls.json' do
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
