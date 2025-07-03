class ClientNotificationsController < ApplicationController
  before_action :authenticate_client!, only: [:index, :update]
  before_action :authenticate_artisan!, only: [:create]

  def index
    notifications = current_client.client_notifications.order(created_at: :desc)
    render json: { notifications: notifications }
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

  def update
  notification = current_client.client_notifications.find(params[:id])

  status = params.dig(:client_notification, :status)

  if notification.update(status: status)
    artisan = notification.artisan

    case status
    when 'accepted'
      artisan.notifications.create!(
        message: "Votre demande a été acceptée par le client. Mission en cours.",
        link: "/annonces/#{besoin_id}",
        status: 'accepted',
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

  private

  # Ne PAS autoriser :link ici, c’est géré côté serveur
  def client_notification_params
    params.require(:client_notification).permit(:client_id, :besoin_id, :message)
  end
end




