class Admin::SessionsController < Devise::SessionsController
  respond_to :json

  def create
    admin = Admin.find_by(email: sign_in_params[:email])
    
    if admin&.valid_password?(sign_in_params[:password])
      if admin.active?
        token = generate_jwt_token(admin)
        
        render json: {
          message: 'Connexion réussie',
          admin: admin.as_json(only: [:id, :email, :first_name, :last_name, :role]),
          token: token
        }, status: :ok
      else
        render json: {
          message: 'Compte administrateur inactif',
          errors: ['Votre compte a été désactivé']
        }, status: :forbidden
      end
    else
      render json: {
        message: 'Identifiants incorrects',
        errors: ['Email ou mot de passe invalide']
      }, status: :unauthorized
    end
  end

  def destroy
    if current_admin
      render json: {
        message: 'Déconnexion réussie'
      }, status: :ok
    else
      render json: {
        message: 'Aucune session active trouvée'
      }, status: :unauthorized
    end
  end

  private

  def sign_in_params
    params.require(:admin).permit(:email, :password)
  end

  def generate_jwt_token(admin)
    payload = {
      sub: admin.id,
      email: admin.email,
      role: admin.role,
      exp: 24.hours.from_now.to_i,
      iat: Time.current.to_i
    }
    # ✅ Correction ici
    JWT.encode(payload, Rails.application.credentials.devise[:jwt_secret_key])
  end
end


