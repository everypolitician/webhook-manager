require 'bundler'
Bundler.require
Dotenv.load

require 'open-uri'
require 'json'
require 'tilt/erb'
require 'active_support/core_ext'

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

require 'app/models'
require 'app/jobs'

helpers do
  def current_user
    @current_user ||= User[session[:user_id]]
  end
end

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

post '/' do
  return "Unhandled GitHub event: #{github_event}" unless github_event == 'pull_request'
  pull_request_action = case payload['action']
  when 'opened'
    :pull_request_opened
  when 'synchronize'
    :pull_request_synchronize
  when 'closed'
    if payload['pull_request']['merged']
      :pull_request_merged
    else
      :pull_request_closed
    end
  else
    halt 400, "Unknown action: #{payload['action']}"
  end
  applications = Application.exclude(webhook_url: '').where(pull_request_action => true)
  applications.each do |application|
    SendWebhookJob.perform_async(
      application.webhook_url,
      pull_request_action,
      payload['number'],
      payload['pull_request']['head']['sha']
    )
  end
  "Dispatched #{applications.count} webhooks"
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
