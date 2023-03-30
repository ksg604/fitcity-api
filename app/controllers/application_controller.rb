class ApplicationController < ActionController::Base
  skip_before_action :verify_authenticity_token

  require "Jwt"

  private
    def authenticate
      user, decoded_token = Jwt::Authenticator.authenticate(request.headers)
      [user, decoded_token]
    end
end
