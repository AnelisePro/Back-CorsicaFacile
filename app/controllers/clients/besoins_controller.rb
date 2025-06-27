module Clients
  class BesoinsController < ApplicationController
    before_action :authenticate_client!

    def create
      besoin = current_client.besoins.new(besoin_params)
      if besoin.save
        render json: besoin.as_json(methods: :image_urls), status: :created
      else
        render json: { errors: besoin.errors.full_messages }, status: :unprocessable_entity
      end
    end

    def index
      render json: current_client.besoins.as_json(methods: :image_urls)
    end

    def update
      besoin = current_client.besoins.find_by(id: params[:id])
      if besoin
        if besoin.update(besoin_params)
          render json: besoin.as_json(methods: :image_urls), status: :ok
        else
          render json: { errors: besoin.errors.full_messages }, status: :unprocessable_entity
        end
      else
        render json: { error: 'Besoin non trouvé' }, status: :not_found
      end
    end

    def destroy
      besoin = current_client.besoins.find_by(id: params[:id])
      if besoin
        besoin.destroy
        head :no_content
      else
        render json: { error: 'Besoin non trouvé' }, status: :not_found
      end
    end

    private

    def besoin_params
      params.require(:besoin).permit(:type_prestation, :description, :schedule, :address, image_urls: [])
    end
  end
end





