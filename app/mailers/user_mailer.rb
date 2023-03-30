class UserMailer < ApplicationMailer
  default from: 'kevin.sangab@gmail.com'
  layout "mailer"

  def send_password_reset_email(user_email)
    @password_reset_url = params[:password_reset_url]
    mail(to: user_email, subject: 'Reset Your Password')
  end
end
