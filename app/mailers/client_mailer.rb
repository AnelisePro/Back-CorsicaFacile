class ClientMailer < ApplicationMailer
  default from: ENV['SMTP_USER']

  def welcome_email(client)
    @client = client
    mail(to: @client.email, subject: 'Bienvenue sur CorsicaFacile !')
  end

  def account_deleted_email(client)
    @client = client
    mail(to: @client.email, subject: 'Confirmation de suppression de votre compte CorsicaFacile')
  end

  def reset_password_email(client, reset_token)
    @client = client
    @reset_token = reset_token
    @reset_url = "#{ENV['FRONTEND_URL']}/auth/reset-password-client?token=#{reset_token}"
    mail(to: @client.email, subject: 'Réinitialisation de votre mot de passe CorsicaFacile')
  end
end
