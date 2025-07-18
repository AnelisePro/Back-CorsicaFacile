class Artisans::BesoinsController < ApplicationController
  before_action :authenticate_artisan!

  def index
    besoins = Besoin.includes(:client)
                   .joins("LEFT JOIN client_notifications ON besoins.id = client_notifications.besoin_id")
                   .where("client_notifications.status IS NULL OR client_notifications.status != 'completed'")
                   .distinct
    
    render json: besoins.as_json(
      methods: :image_urls,
      include: { client: { only: [:id, :first_name, :last_name, :email, :phone, :avatar_url] } }
    )
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
    
    render json: besoin.as_json(
      methods: :image_urls,
      include: { client: { only: [:id, :first_name, :last_name, :email, :phone, :avatar_url] } }
    )
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Besoin non trouvé' }, status: :not_found
  end
end

