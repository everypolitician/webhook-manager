require 'bundler'
Bundler.require
Dotenv.load

require 'json'
require 'tilt/erb'
require 'active_support/core_ext'

$LOAD_PATH << File.expand_path('../lib', __FILE__)
$LOAD_PATH << File.expand_path('../', __FILE__)

configure do
  set :sessions, expire_after: 5.years
  set :session_secret, ENV['SESSION_SECRET']
  set :database, lambda {
    ENV['DATABASE_URL'] ||
      "postgres:///everypolitician_#{environment}"
  }
  set :github_webhook_secret, ENV['GITHUB_WEBHOOK_SECRET']
end

configure :production do
  require 'rollbar/middleware/sinatra'
  require 'rollbar/sidekiq'

  use Rollbar::Middleware::Sinatra

  Rollbar.configure do |config|
    config.access_token = ENV['ROLLBAR_ACCESS_TOKEN']
    config.disable_monkey_patch = true
    config.environment = settings.environment
  end
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
  JSON.pretty_generate(webhook_event_handler_url: url('/event_handler'))
end

post '/event_handler' do
  case request.env['HTTP_X_GITHUB_EVENT']
  when 'pull_request'
    HandleEverypoliticianDataPullRequestJob.perform_async(payload)
    'HandleEverypoliticianDataPullRequestJob queued'
  when 'deployment'
    DeployViewerSinatraPullRequestJob.perform_async(payload)
    'DeployViewerSinatraPullRequestJob queued'
  else
    "Unknown event type: #{request.env['HTTP_X_GITHUB_EVENT']}"
  end
end

post '/applications' do
  halt if current_user.nil?
  @applications = current_user.applications
  @application = Application.new(params[:application])
  @application.user_id = current_user.id
  if @application.valid?
    @application.save
    redirect to('/')
  else
    erb :index
  end
end

get '/applications/:id' do
  halt if current_user.nil?
  @application = current_user.applications_dataset.first(id: params[:id])
  erb :application
end

post '/applications/:application_id/submissions' do
  application = Application[params[:application_id]]
  submission_data = params[:submission]
  updates = submission_data.delete('data')
  begin
    submission = nil
    Submission.db.transaction do
      submission = application.add_submission(submission_data)
      updates.each do |field, value|
        submission.add_update(
          field: field,
          value: value
        )
      end
    end
    flash[:notice] = 'Your update has been submitted for approval'
    redirect to("/applications/#{application.id}/submissions/#{submission.id}")
  rescue Sequel::ValidationFailed => e
    "Invalid submission: #{e.message}"
  end
end

get '/applications/:application_id/submissions/:id' do
  @application = Application[params[:application_id]]
  @submission = @application.submissions_dataset[id: params[:id]]
  erb :new_submission
end

# Mounted under /submissions so we can use basic auth
class Submissions < Sinatra::Base
  use Rack::Auth::Basic do |application_id, secret|
    application = Application.first(app_id: application_id)
    application && application.secret == secret
  end

  get '/' do
    content_type :json
    @application = Application.first(app_id: request.env['REMOTE_USER'])
    @application.submissions_dataset.to_json(include: :updates)
  end

  post '/' do
    application = Application.first(app_id: request.env['REMOTE_USER'])
    submission = application.submission_from_payload(params[:submission])
    AcceptSubmissionJob.perform_async(submission.id)
    'ok'
  end

  post '/accept/:id' do
    application = Application.first(app_id: request.env['REMOTE_USER'])
    submission = application.submissions_dataset[id: params[:id]]
    AcceptSubmissionJob.perform_async(submission.id) if submission
    'OK'
  end
end
