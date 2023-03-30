class PasswordResetToken < ApplicationRecord
  belongs_to :user
  before_create do
    set_encrypted_token
    # set_expiry
  end 

  attr_accessor :token

  def self.verify_token(token)
    PasswordResetToken.find_by(encrypted_token: token)
  end

  private 
    def set_encrypted_token
      self.token = SecureRandom.hex
      self.encrypted_token = Digest::SHA2.new(384).hexdigest(token)
    end

    # def set_expiry
    #   self.exp = Time.now + 30.minutes
    # end
end
