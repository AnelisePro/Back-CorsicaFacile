module Artisans
  class SessionsController < Devise::SessionsController
    respond_to :json

    def create
      artisan = Artisan.find_for_database_authentication(email: params[:artisan][:email])
      
      if artisan && artisan.valid_password?(params[:artisan][:password])
        sign_in(artisan)
        
        # Le token JWT sera généré automatiquement via `devise-jwt`
        render json: {
          message: 'Artisan connecté avec succès',
          artisan: {
          company_name: artisan.company_name,
          address: artisan.address,
          expertise_names: artisan.expertises.pluck(:name),
          siren: artisan.siren,
          email: artisan.email,
          phone: artisan.phone,
          verified: artisan.verified,
          kbis_url: artisan.kbis_url,
          insurance_url: artisan.insurance_url,
          avatar_url: artisan.avatar.attached? ? url_for(artisan.avatar) : nil
        },
          token: request.env['warden-jwt_auth.token']
        }, status: :ok
      else
        render json: { message: 'Email ou mot de passe incorrect' }, status: :unauthorized
      end
    end

    def destroy
      # Lorsque l'utilisateur se déconnecte, tu peux révoquer le token JWT (si nécessaire)
      sign_out(resource_name)
      render json: { message: 'Déconnexion réussie' }, status: :ok
    end

    private

    def respond_to_on_destroy
      # Si tu veux une réponse personnalisée pour la déconnexion
      render json: { message: 'Déconnexion réussie' }, status: :ok
    end
  end
end
