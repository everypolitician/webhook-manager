ENV['RACK_ENV'] = 'test'

require 'simplecov'
SimpleCov.start if ENV['COVERAGE']

require 'minitest/autorun'
require_relative '../app'

Dir['spec/support/**/*.rb'].each { |f| require f }

class Minitest::Spec
  HMAC_DIGEST = OpenSSL::Digest.new('sha1')

  def body_signature(body)
    'sha1=' + OpenSSL::HMAC.hexdigest(
      HMAC_DIGEST,
      app.github_webhook_secret,
      body
    )
  end

  def login!
    get '/auth/github'
    3.times { follow_redirect! }
  end
end
