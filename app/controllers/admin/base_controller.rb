class Admin::BaseController < ApplicationController
  before_action :authenticate_admin!
  before_action :ensure_admin_active
  
  private
  
  def authenticate_admin!
    token = request.headers['Authorization']&.split(' ')&.last
    return render json: { error: 'Token manquant' }, status: :unauthorized unless token
    
    begin
      decoded_token = JWT.decode(token, Rails.application.credentials.devise[:jwt_secret_key]).first
      @current_admin = Admin.find(decoded_token['sub'])
    rescue JWT::DecodeError, ActiveRecord::RecordNotFound
      render json: { error: 'Token invalide' }, status: :unauthorized
    end
  end
  
  def ensure_admin_active
    return render json: { error: 'Compte administrateur inactif' }, status: :forbidden unless @current_admin.active?
  end
  
  def current_admin
    @current_admin
  end
end