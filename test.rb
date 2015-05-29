ENV['RACK_ENV'] = 'test'

require 'minitest/autorun'
require 'rack/test'
require_relative './app'

describe 'App' do
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  describe 'GitHub webhooks' do
    it 'rejects invalid signatures' do
      post '/github_events', {}, 'HTTP_X_HUB_SIGNATURE' => 'sha1=invalid'
      assert_equal 500, last_response.status
      assert_equal "Signatures didn't match!", last_response.body
    end

    it 'accepts valid signatures' do
      sha1 = OpenSSL::Digest.new('sha1')
      body = JSON.generate(
        'action' => 'opened',
        'pull_request' => {
          'user' => {
            'login' => 'seepoliticianstweetbot'
          }
        },
        'repository' => {
          'full_name' => 'test/everypolitician-data'
        }
      )
      signature = 'sha1=' + OpenSSL::HMAC.hexdigest(
        sha1,
        app.github_webhook_secret,
        body
      )
      MergeJob.stub(:perform_async, true) do
        post '/github_events', body, 'HTTP_X_HUB_SIGNATURE' => signature
      end
      assert last_response.ok?
      assert_equal 'OK', last_response.body
    end
  end
end
