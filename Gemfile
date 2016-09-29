source 'https://rubygems.org'

ruby '2.2.3'

git_source(:github) { |repo_name| "https://github.com/#{repo_name}.git" }

gem 'sinatra'
gem 'dotenv'
gem 'sidekiq', '~> 4.2'
gem 'octokit'
gem 'puma'
gem 'sequel'
gem 'rake'
gem 'pg'
gem 'omniauth-github'
gem 'rack-flash3', require: 'rack/flash'
gem 'sinatra-sequel'
gem 'rubocop', require: false
gem 'faraday'
gem 'pry', require: false
gem 'activesupport', require: 'active_support'
gem 'everypolitician', github: 'everypolitician/everypolitician-ruby', ref: '1ab5d5b'
gem 'sinatra-github_webhooks'

# Rollbar integration (oj is recommended)
gem 'rollbar', '~> 2.13'
gem 'oj', '~> 2.12.14'

group :test do
  gem 'minitest'
  gem 'rack-test'
  gem 'simplecov', require: false
  gem 'database_cleaner'
  gem 'webmock'
  gem 'bundler-audit', '~> 0.5'
end
