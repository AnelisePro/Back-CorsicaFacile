class Api::V1::AuthController < ApplicationController
  def current_user
    if client_signed_in?
      render json: {
        authenticated: true,
        user: {
          id: current_client.id,
          name: current_client.respond_to?(:first_name) && current_client.respond_to?(:last_name) ?
                "#{current_client.first_name} #{current_client.last_name}".strip : 
                current_client.email,
          email: current_client.email,
          user_type: 'Client'
        }
      }
    elsif artisan_signed_in?
      render json: {
        authenticated: true,
        user: {
          id: current_artisan.id,
          name: current_artisan.company_name || current_artisan.email,
          email: current_artisan.email,
          user_type: 'Artisan'
        }
      }
    else
      render json: {
        authenticated: false,
        user: nil
      }
    end
  end
end

