class ClientNotificationsController < ApplicationController
  before_action :authenticate_client!, only: [:index, :update, :destroy]
  before_action :authenticate_artisan!, only: [:create, :check_response]

  def index
    notifications = current_client.client_notifications.includes(:besoin, :artisan).order(created_at: :desc)
    
    notifications_with_titles = notifications.map do |notification|
      {
        id: notification.id,
        message: notification.message,
        link: notification.link,
        artisan_id: notification.artisan_id,
        artisan_name: notification.artisan.company_name,
        status: notification.status,
        besoin_id: notification.besoin_id,
        annonce_title: notification.besoin.type_prestation
      }
    end
    
    render json: { notifications: notifications_with_titles }
  end

  def create
    notification = ClientNotification.new(client_notification_params)
    notification.artisan_id = current_artisan.id
    notification.status = 'pending'
    notification.link = "/artisan-profile/#{notification.artisan_id}"

    if notification.save
      render json: notification, status: :created
    else
      render json: { errors: notification.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def check_response
    besoin_id = params[:besoin_id]
    artisan_id = current_artisan.id

    has_responded = ClientNotification.exists?(
      client_id: params[:client_id],
      besoin_id: besoin_id,
      artisan_id: artisan_id
    )

    render json: { hasResponded: has_responded }
  end

  def update
    notification = current_client.client_notifications.find(params[:id])
    status = params.dig(:client_notification, :status)

    if notification.update(status: status)
      artisan = notification.artisan
      besoin_id = notification.besoin_id

      case status
      when 'accepted'
        artisan.notifications.create!(
          message: "Votre demande a été acceptée par le client. Mission en cours.",
          link: "/annonces/#{besoin_id}",
          status: 'accepted',
          read: false
        )
      when 'in_progress'
        artisan.notifications.create!(
          message: "La mission est en cours.",
          link: "/annonces/#{besoin_id}",
          status: 'in_progress',
          read: false
        )
      when 'refused'
        artisan.notifications.create!(
          message: "Votre demande a été refusée par le client.",
          link: "/annonces/#{besoin_id}",
          status: 'refused',
          read: false
        )
      when 'completed'
        artisan.notifications.create!(
          message: "La mission a été marquée comme terminée par le client.",
          link: "/annonces/#{besoin_id}",
          status: 'completed',
          read: false
        )
      end

      render json: notification
    else
      render json: { errors: notification.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    notification = current_client.client_notifications.find(params[:id])

    if notification.destroy
      render json: { message: 'Notification supprimée avec succès.' }, status: :ok
    else
      render json: { errors: ['Impossible de supprimer la notification.'] }, status: :unprocessable_entity
    end
  end

  private

  def client_notification_params
    params.require(:client_notification).permit(:client_id, :besoin_id, :message, :link)
  end
end






