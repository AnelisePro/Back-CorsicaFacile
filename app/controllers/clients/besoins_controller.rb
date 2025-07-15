module Clients
  class BesoinsController < ApplicationController
    before_action :authenticate_client!

    def create
      besoin_attributes = build_besoin_attributes_for_create
      besoin = current_client.besoins.new(besoin_attributes)
      
      Rails.logger.info "Création besoin avec attributes: #{besoin_attributes.inspect}"
      
      if besoin.save
        Rails.logger.info "Besoin sauvegardé avec schedule: #{besoin.schedule.inspect}"
        NotifyArtisansService.new(besoin).call
        render json: besoin_json(besoin), status: :created
      else
        Rails.logger.error "Erreurs validation: #{besoin.errors.full_messages}"
        render json: { errors: besoin.errors.full_messages }, status: :unprocessable_entity
      end
    end

    def update
      besoin = current_client.besoins.find_by(id: params[:id])
      if besoin
        besoin_attributes = build_besoin_attributes_for_update
        
        if besoin.update(besoin_attributes)
          render json: besoin_json(besoin), status: :ok
        else
          render json: { errors: besoin.errors.full_messages }, status: :unprocessable_entity
        end
      else
        render json: { error: 'Besoin non trouvé' }, status: :not_found
      end
    end

    def show
      besoin = current_client.besoins.find_by(id: params[:id])
      if besoin
        render json: besoin_json(besoin)
      else
        render json: { error: 'Besoin non trouvé' }, status: :not_found
      end
    end

    def index
      besoins = current_client.besoins.all
      render json: besoins.map { |besoin| besoin_json(besoin) }
    end

    def destroy
      besoin = current_client.besoins.find_by(id: params[:id])
      if besoin
        besoin.destroy
        render json: { message: 'Besoin supprimé avec succès' }, status: :ok
      else
        render json: { error: 'Besoin non trouvé' }, status: :not_found
      end
    end

    private

    def build_besoin_attributes_for_create
      attributes = {
        type_prestation: params[:type_prestation],
        description: params[:description],
        address: params[:address]
      }
      
      # Gérer le schedule
      if params[:schedule].present?
        schedule_data = {
          date: params[:schedule][:date],
          start: params[:schedule][:start],
          end: params[:schedule][:end]
        }
        attributes[:schedule] = schedule_data.to_json
      end
      
      # Gérer les images
      if params[:images].present?
        attributes[:image_urls] = params[:images]
      end
      
      Rails.logger.info "Attributs construits (create): #{attributes.inspect}"
      attributes
    end

    def build_besoin_attributes_for_update
      besoin_params = params.require(:besoin)
      
      attributes = {
        type_prestation: besoin_params[:type_prestation],
        description: besoin_params[:description],
        address: besoin_params[:address]
      }
      
      # Gérer le schedule
      if besoin_params[:schedule].present?
        schedule_data = {
          date: besoin_params[:schedule][:date],
          start: besoin_params[:schedule][:start],
          end: besoin_params[:schedule][:end]
        }
        attributes[:schedule] = schedule_data.to_json
      end
      
      # Gérer les images
      if besoin_params[:image_urls].present?
        attributes[:image_urls] = besoin_params[:image_urls]
      end
      
      Rails.logger.info "Attributs construits (update): #{attributes.inspect}"
      attributes
    end

    def besoin_json(besoin)
      Rails.logger.info "=== DEBUG BESOIN #{besoin.id} ==="
      Rails.logger.info "Schedule raw: #{besoin.schedule.inspect}"
      Rails.logger.info "Schedule class: #{besoin.schedule.class}"
      
      # Parser le schedule JSON stocké en base
      schedule_obj = if besoin.schedule.present?
        begin
          parsed = JSON.parse(besoin.schedule)
          Rails.logger.info "Schedule parsé avec succès: #{parsed.inspect}"
          parsed
        rescue JSON::ParserError => e
          Rails.logger.error "Erreur parsing schedule: #{e.message}"
          { date: '', start: '', end: '' }
        end
      else
        Rails.logger.info "Schedule vide ou nil"
        { date: '', start: '', end: '' }
      end
      
      Rails.logger.info "Final schedule_obj: #{schedule_obj.inspect}"
      Rails.logger.info "=== FIN DEBUG ==="

      besoin.as_json(only: [:id, :type_prestation, :description, :address]).merge(
        schedule: schedule_obj,
        images: besoin.image_urls
      )
    end
  end
end








