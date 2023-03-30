class ShopifyAuthController < ApplicationController
  def login
    shop = request.headers["Shop"]

    auth_response = ShopifyAPI::Auth::Oauth.begin_auth(shop: "fitcitydev.myshopify.com", redirect_path: "/api/auth/callback")
  
    # This is the authorization grant
    cookies[auth_response[:cookie].name] = {
      expires: auth_response[:cookie].expires,
      secure: false,
      http_only: true,
      value: auth_response[:cookie].value
    }

    head 307
    response.set_header("Location", auth_response[:auth_route])
  end

  def callback
    begin
      keys = request.parameters.symbolize_keys 

      # Request an access token by authenticating with API (need authorization grant)
      auth_result = ShopifyAPI::Auth::Oauth.validate_auth_callback(
        cookies: cookies.to_h,
        auth_query: ShopifyAPI::Auth::Oauth::AuthQuery.new(code: keys[:code], shop: keys[:shop], timestamp: keys[:timestamp], state: keys[:state], host: keys[:host], hmac: keys[:hmac])
      )
  
      cookies[auth_result[:cookie].name] = {
        expires: auth_result[:cookie].expires,
        secure: false,
        http_only: true,
        value: auth_result[:cookie].value
      }
  
      puts("OAuth complete! New access token: #{auth_result[:session].access_token}")
  
      head 307
      response.set_header("Location", "http://10.0.0.31:3000")
    rescue => exception
      puts(exception.message)
      head 500
    end
  end
end
