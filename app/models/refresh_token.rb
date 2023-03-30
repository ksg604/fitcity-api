class RefreshToken < ApplicationRecord
  belongs_to :user
  before_create :init_token

  attr_accessor :token

  def self.find_by_token(refresh_token)
    encrypted_token = Digest::SHA256.hexdigest refresh_token
    RefreshToken.find_by(encrypted_token: encrypted_token)
  end

  private 
    def init_token
      # Set encrypted token
      self.token = SecureRandom.hex
      self.encrypted_token = Digest::SHA256.hexdigest(token)
      self.exp = Time.now + 24.hours # Refresh tokens expire in 24 hours
    end
end
