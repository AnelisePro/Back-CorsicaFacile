module Clients
  class RegistrationsController < Devise::RegistrationsController
    respond_to :json

    private

    # Permet de définir les paramètres d'inscription personnalisés
    def sign_up_params
      params.require(:client).permit(:first_name, :last_name, :birthdate, :phone, :email, :password, :password_confirmation)
    end

    # Réponse après l'inscription réussie ou échouée
    def respond_with(resource, _opts = {})
      if resource.persisted?
        ClientMailer.welcome_email(resource).deliver_now
        
        render json: {
          message: 'Client inscrit avec succès',
          client: resource,
          token: request.env['warden-jwt_auth.token']
        }, status: :ok
      else
        render json: {
          message: 'Erreur lors de l’inscription',
          errors: resource.errors.full_messages
        }, status: :unprocessable_entity
      end
    end
  end
end