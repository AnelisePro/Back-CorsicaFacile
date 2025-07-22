class ArtisanMailer < ApplicationMailer
  default from: ENV['SMTP_USER']

  def welcome_email(artisan)
    @artisan = artisan
    mail(to: @artisan.email, subject: 'Bienvenue sur CorsicaFacile !')
  end
end