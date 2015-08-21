require 'openssl'

# Sinatra route helpers.
module Helpers
  HMAC_DIGEST = OpenSSL::Digest.new('sha1')

  def payload
    JSON.parse(payload_body)
  end

  def payload_body
    request.body.rewind
    payload_body = request.body.read
    verify_signature(payload_body)
    payload_body
  end

  # Taken from https://developer.github.com/webhooks/securing/
  def verify_signature(payload_body)
    signature = 'sha1=' + OpenSSL::HMAC.hexdigest(
      HMAC_DIGEST,
      settings.github_webhook_secret,
      payload_body
    )
    signatures_match = Rack::Utils.secure_compare(
      signature,
      request.env['HTTP_X_HUB_SIGNATURE']
    )
    return halt 500, "Signatures didn't match!" unless signatures_match
  end

  def current_user
    @current_user ||= User[session[:user_id]]
  end

  def application_url(application, url)
    uri = URI.parse(url)
    uri.user = application.app_id
    uri.password = application.secret
    uri
  end
end
