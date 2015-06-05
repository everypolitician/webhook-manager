ENV['RACK_ENV'] = 'test'

require 'simplecov'
SimpleCov.start

require 'minitest/autorun'
require 'rack/test'
require_relative '../app'

class Minitest::Spec
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end
end

OmniAuth.config.test_mode = true

OmniAuth.config.mock_auth[:github] = OmniAuth::AuthHash.new(
  provider: 'github',
  uid: '123545',
  info: {
    name: 'Bob Test',
    email: 'bob@example.org'
  },
  credentials: {
    token: 'abc123'
  }
)
