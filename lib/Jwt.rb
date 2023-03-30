module Jwt
  module Authenticator    
    module_function
    def authenticate(headers)
      require_relative "./error/Errors"
      encrypted_access_token = headers.fetch("Authorization", "").split("Bearer ")[1]

      raise ActionController::BadRequest.new("Missing Access Token") unless encrypted_access_token.present?

      decoded_token = Jwt::Decoder.decode!(encrypted_access_token)

      user = authenticate_user_from_token(decoded_token)

      [user, decoded_token]
    end

    def authenticate_user_from_token(decoded_token)
      require "Errors"
      raise Errors::MissingToken.new("Missing Access Token", "Access Token") unless decoded_token.present?
      raise ActionController::BadRequest.new("Invalid Access Token") unless decoded_token[:jti].present? && decoded_token[:user_id].present?

      user = User.find_by(id: decoded_token.fetch(:user_id))

      valid_iat = valid_iat?(decoded_token, user)

      return user if valid_iat
    end

    def valid_iat?(decoded_token, user)
      !user.token_iat || decoded_token.fetch(:iat) >= user.token_iat
    end
  end

  module Decoder
    module_function
    
    def decode!(access_token)
      begin
        decoded_token = JWT.decode(access_token, key = Jwt::Secret.secrets, verify = true, options = { algorithm: "HS256" })[0]
        decoded_token.symbolize_keys
      rescue JWT::ExpiredSignature
        nil
      end
    end
  end

  module Encoder
    module_function

    def encode(user)
      jti = SecureRandom.hex
      exp = Jwt::Encoder.token_expiry.to_i
      iat = Jwt::Encoder.token_iat.to_i
      access_token = JWT.encode(
        {
          user_id: user.id,
          jti: jti,
          iat: iat,
          exp: exp
        }, Jwt::Secret.secrets
      )

      [access_token, jti, iat, exp]
    end

    def token_expiry
      (Jwt::Encoder.token_iat + Jwt::Expiry.expiry)
    end

    def token_iat
      Time.now
    end
  end

  module Expiry
    module_function
    def expiry
      20.seconds
    end
  end

  module Issuer
    module_function
    def issue_tokens(user)
      access_token, jti, iat, exp = Jwt::Encoder.encode(user)
      user.token_iat = iat

      refresh_token = user.refresh_tokens.create!
      [access_token, refresh_token]
    end
  end 

  module Secret
    module_function
    def secrets
      Rails.application.secrets.secret_key_base
    end
  end

  module Refresh
    module_function
    def refresh!(refresh_token)
      require "Errors"

      raise Errors::InvalidToken.new("Missing Token", "Refresh Token") unless refresh_token.present?

      existing_refresh_token = RefreshToken.find_by(encrypted_token: refresh_token)
      raise Errors::InvalidToken.new("Invalid Refresh Token", "Refresh Token") unless existing_refresh_token.present?
      user = User.find_by(id: existing_refresh_token.user_id)

      existing_refresh_token.destroy!
      new_access_token, new_refresh_token = Jwt::Issuer.issue_tokens(user)

      puts "new refresh token: #{new_refresh_token}"

      [new_access_token, new_refresh_token]
    end
  end
  
  module Revoker
    module_function
    def revoke(refresh_token)
      # Destroy refresh token if user manually logs out
      existing_refresh_token = RefreshToken.find_by(encrypted_token: refresh_token)
      existing_refresh_token.destroy if existing_refresh_token.present?
    end
  end
end