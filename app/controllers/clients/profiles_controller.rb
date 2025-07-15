module Clients
  class ProfilesController < ApplicationController
    before_action :authenticate_client!
    include Rails.application.routes.url_helpers

    def show
      render json: {
        client: client_json(current_client)
      }
    end

    def update
      permitted_params = params.require(:client).permit(
        :first_name, :last_name, :email, :birthdate, :phone,
        :password, :password_confirmation, :avatar_url
      )

      if current_client.update(permitted_params)
        render json: {
          client: client_json(current_client)
        }, status: :ok
      else
        render json: { errors: current_client.errors.full_messages }, status: :unprocessable_entity
      end
    end

    def destroy
      current_client.destroy
      head :no_content
    end

    private

    def client_json(client)
      client.as_json(only: [:id, :first_name, :last_name, :email, :birthdate, :phone, :avatar_url])
    end
  end
end


