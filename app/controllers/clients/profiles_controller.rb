module Clients
  class ProfilesController < ApplicationController
    before_action :authenticate_client!

    def show
      render json: {
        client: current_client.as_json(only: [:id, :first_name, :last_name, :email, :birthdate, :phone])
      }
    end

    def update
      if current_client.update(params.require(:client).permit(
        :first_name, :last_name, :email, :birthdate, :phone,
        :password, :password_confirmation
      ))
        render json: {
          client: current_client.as_json(only: [:id, :first_name, :last_name, :email, :birthdate, :phone])
        }, status: :ok
      else
        render json: { errors: current_client.errors.full_messages }, status: :unprocessable_entity
      end
    end

    def destroy
      current_client.destroy
      head :no_content
    end
  end
end
