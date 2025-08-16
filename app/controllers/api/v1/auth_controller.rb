class Api::V1::AuthController < ApplicationController
  def current_user
    if client_signed_in?
      user_data = current_client.as_json(only: [:id, :email, :first_name, :last_name])
      user_data[:name] = "#{current_client.first_name} #{current_client.last_name}".strip
      user_data[:user_type] = 'Client'
      
      render json: {
        authenticated: true,
        user: user_data
      }
    elsif artisan_signed_in?
      user_data = current_artisan.as_json(only: [:id, :email, :company_name])
      user_data[:name] = current_artisan.company_name || 'Artisan'
      user_data[:user_type] = 'Artisan'
      
      render json: {
        authenticated: true,
        user: user_data
      }
    else
      render json: {
        authenticated: false,
        user: nil
      }
    end
  end
end
