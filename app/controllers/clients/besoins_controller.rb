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
      
      # Ajouter custom_prestation si présent
      if params[:custom_prestation].present?
        attributes[:custom_prestation] = params[:custom_prestation]
      end
      
      # Gérer la nouvelle structure de schedule
      if params[:schedule].present?
        schedule_data = build_schedule_data(params[:schedule])
        attributes[:schedule] = schedule_data.to_json
        Rails.logger.info "Schedule construit: #{schedule_data.inspect}"
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
      
      # Ajouter custom_prestation si présent
      if besoin_params[:custom_prestation].present?
        attributes[:custom_prestation] = besoin_params[:custom_prestation]
      end
      
      # Gérer la nouvelle structure de schedule
      if besoin_params[:schedule].present?
        schedule_data = build_schedule_data(besoin_params[:schedule])
        attributes[:schedule] = schedule_data.to_json
        Rails.logger.info "Schedule construit (update): #{schedule_data.inspect}"
      end
      
      # Gérer les images
      if besoin_params[:image_urls].present?
        attributes[:image_urls] = besoin_params[:image_urls]
      end
      
      Rails.logger.info "Attributs construits (update): #{attributes.inspect}"
      attributes
    end

    # Nouvelle méthode pour construire les données de schedule
    def build_schedule_data(schedule_params)
      schedule_data = {
        type: schedule_params[:type],
        start_time: schedule_params[:start_time],
        end_time: schedule_params[:end_time]
      }

      case schedule_params[:type]
      when 'single_day'
        schedule_data[:date] = schedule_params[:date] if schedule_params[:date].present?
      when 'date_range'
        schedule_data[:start_date] = schedule_params[:start_date] if schedule_params[:start_date].present?
        schedule_data[:end_date] = schedule_params[:end_date] if schedule_params[:end_date].present?
      end

      # Maintenir la compatibilité avec l'ancien format pour les services existants
      # (vous pouvez supprimer cette partie plus tard si nécessaire)
      if schedule_params[:type] == 'single_day' && schedule_params[:date].present?
        schedule_data[:start] = schedule_params[:start_time] # Pour rétro-compatibilité
        schedule_data[:end] = schedule_params[:end_time]     # Pour rétro-compatibilité
      end

      schedule_data
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
          
          # Migration automatique de l'ancien format vers le nouveau
          if parsed['date'].present? && !parsed['type']
            Rails.logger.info "Migration d'un ancien schedule vers le nouveau format"
            migrated_schedule = {
              'type' => 'single_day',
              'date' => parsed['date'],
              'start_time' => parsed['start'] || parsed['start_time'],
              'end_time' => parsed['end'] || parsed['end_time']
            }
            Rails.logger.info "Schedule migré: #{migrated_schedule.inspect}"
            migrated_schedule
          else
            parsed
          end
        rescue JSON::ParserError => e
          Rails.logger.error "Erreur parsing schedule: #{e.message}"
          { 
            'type' => 'single_day', 
            'date' => '', 
            'start_time' => '', 
            'end_time' => '' 
          }
        end
      else
        Rails.logger.info "Schedule vide ou nil"
        { 
          'type' => 'single_day', 
          'date' => '', 
          'start_time' => '', 
          'end_time' => '' 
        }
      end
      
      Rails.logger.info "Final schedule_obj: #{schedule_obj.inspect}"
      Rails.logger.info "=== FIN DEBUG ==="

      result = besoin.as_json(only: [:id, :type_prestation, :description, :address]).merge(
        schedule: schedule_obj,
        images: besoin.image_urls || []
      )

      # Ajouter custom_prestation si présent
      if besoin.respond_to?(:custom_prestation) && besoin.custom_prestation.present?
        result[:custom_prestation] = besoin.custom_prestation
      end

      result
    end
  end
end









