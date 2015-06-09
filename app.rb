require 'bundler'
Bundler.require
Dotenv.load

require 'json'
require 'tilt/erb'

$LOAD_PATH << File.expand_path('../lib', __FILE__)
$LOAD_PATH << File.expand_path('../', __FILE__)

configure do
  enable :sessions
  set :session_secret, ENV['SESSION_SECRET']
  set :database, lambda {
    ENV['DATABASE_URL'] ||
      "postgres:///everypolitician_#{environment}"
  }
  set :github_webhook_secret, ENV['GITHUB_WEBHOOK_SECRET']
end

require 'helpers'
require 'app/models'
require 'app/jobs'

helpers Helpers

use OmniAuth::Builder do
  provider :github, ENV['GITHUB_KEY'], ENV['GITHUB_SECRET'], scope: 'user:email'
end

use Rack::Flash

get '/' do
  if current_user
    @application = Application.new
    @applications = current_user.applications
  end
  erb :index
end

get '/auth/github/callback' do
  auth = request.env['omniauth.auth']
  user = User.first(github_uid: auth[:uid])
  if user
    session[:user_id] = user.id
  else
    user = User.create(
      name: auth[:info][:name],
      email: auth[:info][:email],
      github_uid: auth[:uid],
      github_token: auth[:credentials][:token]
    )
    session[:user_id] = user.id
  end
  flash[:notice] = 'You have successfully logged in with GitHub'
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

post '/applications' do
  halt if current_user.nil?
  @applications = current_user.applications
  @application = Application.new(params[:application])
  @application.user_id = current_user.id
  @application.secret = SecureRandom.hex(20)
  if @application.valid?
    @application.save
    redirect to('/')
  else
    erb :index
  end
end

post '/applications/:application_id/submissions' do
  application = Application[params[:application_id]]
  submission_data = params[:submission]
  # submission_data[:data] = JSON.generate(submission_data[:data])
  begin
    submission = application.add_submission(submission_data)
    flash[:notice] = 'Your update has been submitted for approval'
    redirect to("/applications/#{application.id}/submissions/#{submission.id}")
  rescue Sequel::ValidationFailed => e
    "Invalid submission: #{e.message}"
  end
end

get '/applications/:application_id/submissions' do
  content_type :json
  @application = Application[params[:application_id]]
  @application.submissions_dataset.to_json
end

get '/applications/:application_id/submissions/:id' do
  @application = Application[params[:application_id]]
  @submission = application.submissions_dataset[id: params[:id]]
  erb :new_submission
end

# Mounted under /accept_submission so we can use basic auth
class AcceptSubmission < Sinatra::Base
  use Rack::Auth::Basic do |application_id, secret|
    Application[application_id].secret == secret
  end

  post '/:id' do
    application = Application[request.env['REMOTE_USER']]
    submission = application.submissions_dataset[id: params[:id]]
    AcceptSubmissionJob.perform_async(submission.id) if submission
    'OK'
  end
end
