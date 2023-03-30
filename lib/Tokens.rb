module Tokens
  module PasswordResetToken
    module_function
    def issue_token(user)
      token = user.password_reset_tokens.create!(
        exp: Tokens::PasswordResetToken.expiry.to_i
      )
    end

    def expiry
      (Tokens::PasswordResetToken.token_iat + 30.minutes)
    end

    def token_iat
      Time.now
    end
  end
end