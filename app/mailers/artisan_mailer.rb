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
    @reset_url = "#{ENV['FRONTEND_URL']}/auth/reset-password-artisan?token=#{reset_token}"
    mail(to: @artisan.email, subject: 'Réinitialisation de votre mot de passe CorsicaFacile')
  end

  def document_renewal_reminder(artisan, months_remaining)
    @artisan = artisan
    @months_remaining = months_remaining
    @company_name = artisan.company_name
    @dashboard_url = "#{ENV['FRONTEND_URL']}/dashboard/artisan"
    
    subject = case months_remaining
    when 0
      "🔴 URGENT - Votre abonnement expire ce mois-ci !"
    when 1
      "⚠️ Votre abonnement expire dans 1 mois"
    else
      "📅 Rappel - Votre abonnement expire dans #{months_remaining} mois"
    end
    
    mail(to: @artisan.email, subject: subject)
  end
end