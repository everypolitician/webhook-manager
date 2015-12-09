# Sinatra route helpers.
module Helpers
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
