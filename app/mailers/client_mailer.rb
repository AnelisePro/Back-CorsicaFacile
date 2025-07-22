class ClientMailer < ApplicationMailer
  default from: ENV['SMTP_USER']

  def welcome_email(client)
    @client = client
    mail(to: @client.email, subject: 'Bienvenue sur CorsicaFacile !')
  end
end