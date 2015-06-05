ENV['RACK_ENV'] = 'test'

require 'simplecov'
SimpleCov.start if ENV['COVERAGE']

require 'minitest/autorun'
require 'rack/test'
require 'database_cleaner'
require_relative '../app'

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

DatabaseCleaner.strategy = :transaction

class Minitest::Spec
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  before :each do
    DatabaseCleaner.start
  end

  after :each do
    DatabaseCleaner.clean
  end

  # Copied from active support http://git.io/vIYii
  def assert_difference(expression, difference = 1, message = nil, &block)
    expressions = Array(expression)

    exps = expressions.map do |e|
      e.respond_to?(:call) ? e : -> { eval(e, block.binding) }
    end
    before = exps.map(&:call)

    yield

    expressions.zip(exps).each_with_index do |(code, e), i|
      error  = "#{code.inspect} didn't change by #{difference}"
      error  = "#{message}.\n#{error}" if message
      assert_equal(before[i] + difference, e.call, error)
    end
  end
end
