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
