class Api::V1::PasswordResetsController < ApplicationController
  before_action :validate_email_format, only: [:create_artisan, :create_client]

  # POST /api/v1/password_resets/artisan
  def create_artisan
    artisan = Artisan.find_by(email: params[:email])
    
    if artisan
      # Générer un token de réinitialisation
      reset_token = SecureRandom.urlsafe_base64(32)
      
      # Sauvegarder le token avec expiration (1 heure)
      artisan.update!(
        reset_password_token: reset_token,
        reset_password_sent_at: Time.current
      )
      
      # Envoyer l'email
      ArtisanMailer.reset_password_email(artisan, reset_token).deliver_now
      
      render json: { 
        message: "Un lien de réinitialisation a été envoyé à #{params[:email]}" 
      }, status: :ok
    else
      render json: { 
        message: "Aucun compte artisan trouvé avec cette adresse email" 
      }, status: :not_found
    end
  rescue => e
    Rails.logger.error "Erreur envoi email artisan: #{e.message}"
    render json: { 
      message: "Erreur lors de l'envoi de l'email" 
    }, status: :internal_server_error
  end

  # POST /api/v1/password_resets/client  
  def create_client
    client = Client.find_by(email: params[:email])
    
    if client
      # Générer un token de réinitialisation
      reset_token = SecureRandom.urlsafe_base64(32)
      
      # Sauvegarder le token avec expiration (1 heure)
      client.update!(
        reset_password_token: reset_token,
        reset_password_sent_at: Time.current
      )
      
      # Envoyer l'email
      ClientMailer.reset_password_email(client, reset_token).deliver_now
      
      render json: { 
        message: "Un lien de réinitialisation a été envoyé à #{params[:email]}" 
      }, status: :ok
    else
      render json: { 
        message: "Aucun compte client trouvé avec cette adresse email" 
      }, status: :not_found
    end
  rescue => e
    Rails.logger.error "Erreur envoi email client: #{e.message}"
    render json: { 
      message: "Erreur lors de l'envoi de l'email" 
    }, status: :internal_server_error
  end

  private

  def validate_email_format
    unless params[:email].present? && params[:email].match?(/\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i)
      render json: { message: "Format d'email invalide" }, status: :unprocessable_entity
    end
  end
end
