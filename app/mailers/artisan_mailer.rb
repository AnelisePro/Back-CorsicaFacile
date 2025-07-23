class ArtisanMailer < ApplicationMailer
  default from: ENV['SMTP_USER']

  def welcome_email(artisan)
    @artisan = artisan
    mail(to: @artisan.email, subject: 'Bienvenue sur CorsicaFacile !')
  end

  def account_deleted_email(artisan)
    @artisan = artisan
    mail(to: @artisan.email, subject: 'Confirmation de suppression de votre compte CorsicaFacile')
  end

  def reset_password_email(artisan, reset_token)
    @artisan = artisan
    @reset_token = reset_token
    @reset_url = "#{ENV['FRONTEND_URL']}/auth/passwords/artisan?token=#{reset_token}"
    mail(to: @artisan.email, subject: 'Réinitialisation de votre mot de passe CorsicaFacile')
  end
end