module Clients
  class BesoinsController < ApplicationController
    before_action :authenticate_client!

    def create
      besoin = current_client.besoins.new(besoin_params)
      if besoin.save
        NotifyArtisansService.new(besoin).call
        render json: besoin_json(besoin), status: :created
      else
        render json: { errors: besoin.errors.full_messages }, status: :unprocessable_entity
      end
    end

    def index
      besoins = current_client.besoins
      render json: besoins.map { |besoin| besoin_json(besoin) }
    end

    def update
      besoin = current_client.besoins.find_by(id: params[:id])
      if besoin
        if besoin.update(besoin_params)
          render json: besoin_json(besoin), status: :ok
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
      params.require(:besoin).permit(:type_prestation, :description, :schedule, :address, :custom_prestation, image_urls: [])
    end

    def besoin_json(besoin)
      besoin.as_json(only: [:id, :type_prestation, :description, :schedule, :address]).merge(
        images: besoin.image_urls
      )
    end
  end
end






