require 'dotenv/tasks'
task app: :dotenv do
  require_relative './app'
end

namespace :db do
  desc 'Run migrations'
  task :migrate, [:version] => :app do |_t, args|
    require 'sequel'
    Sequel.extension :migration
    db = Sinatra::Application.database
    if args[:version]
      puts "Migrating to version #{args[:version]}"
      Sequel::Migrator.run(db, 'db/migrations', target: args[:version].to_i)
    else
      puts 'Migrating to latest'
      Sequel::Migrator.run(db, 'db/migrations')
    end
  end
end

require 'rake/testtask'
Rake::TestTask.new do |t|
  t.libs << 'spec'
  t.test_files = FileList['spec/*_spec.rb']
  t.verbose = true
end

require 'rubocop/rake_task'
RuboCop::RakeTask.new

namespace :webhooks do
  desc 'Configure webhooks on GitHub'
  task configure: :app do
    require 'open-uri'
    require 'json'
    require 'github'
    urls = open('https://app-manager.herokuapp.com/urls.json').read
    urls = JSON.parse(urls)
    event_handler_url = urls['webhook_event_handler_url']
    include Github
    webhooks = github.hooks(ENV['EVERYPOLITICIAN_DATA_REPO'])
    webhook = webhooks.find { |h| h[:config][:url] == event_handler_url }
    if webhook.nil?
      config = {
        url: event_handler_url,
        content_type: 'json',
        secret: ENV['GITHUB_WEBHOOK_SECRET']
      }
      options = { events: [:push, :pull_request, :deployment], active: true }
      repos = [ENV['EVERYPOLITICIAN_DATA_REPO'], ENV['VIEWER_SINATRA_REPO']]
      repos.each do |repo|
        github.create_hook(
          repo,
          'web',
          config,
          options
        )
      end
      puts 'Webhook created'
    end
  end
end

task default: [:test, :rubocop]
