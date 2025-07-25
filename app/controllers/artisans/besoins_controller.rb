class Artisans::BesoinsController < ApplicationController
  before_action :authenticate_artisan!

  def index
    besoins = Besoin.includes(:client)
                   .joins("LEFT JOIN client_notifications ON besoins.id = client_notifications.besoin_id")
                   .where("client_notifications.status IS NULL OR client_notifications.status != 'completed'")
                   .distinct
    
    render json: besoins.as_json(
      methods: [:image_urls, :parsed_schedule],
      include: { client: { only: [:id, :first_name, :last_name, :email, :phone, :avatar_url] } }
    ).map { |besoin| format_besoin_response(besoin) }
  end

  def show
    besoin = Besoin.find(params[:id])
    
    # Vérifier si l'annonce est terminée
    completed_notification = ClientNotification.find_by(besoin_id: besoin.id, status: 'completed')
    
    if completed_notification
      render json: { 
        error: 'Cette annonce n\'existe plus',
        message: 'Cette annonce a été terminée et n\'est plus disponible.',
        is_completed: true
      }, status: 410 # Gone
      return
    end
    
    response_data = besoin.as_json(
      methods: [:image_urls, :parsed_schedule],
      include: { client: { only: [:id, :first_name, :last_name, :email, :phone, :avatar_url] } }
    )
    
    render json: format_besoin_response(response_data)
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Besoin non trouvé' }, status: :not_found
  end

  private

  def format_besoin_response(besoin_data)
    # Remplacer le schedule string par l'objet parsé
    if besoin_data['parsed_schedule']
      besoin_data['schedule'] = besoin_data['parsed_schedule']
      besoin_data.delete('parsed_schedule')
    end
    besoin_data
  end
end


