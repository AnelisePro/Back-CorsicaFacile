module Clients
  class SessionsController < Devise::SessionsController
    respond_to :json

    private

    def respond_with(resource, _opts = {})
      token = request.env['warden-jwt_auth.token']
      response.set_header('Authorization', "Bearer #{token}") if token

      render json: {
        message: 'Client connecté avec succès',
        client: resource.as_json(only: [:id, :first_name, :last_name, :email, :birthdate, :phone]),
      }, status: :ok
    end

    def respond_to_on_destroy
      render json: { message: 'Déconnexion réussie' }, status: :ok
    end
  end
end