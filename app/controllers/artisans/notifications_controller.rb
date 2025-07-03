class Artisans::NotificationsController < ApplicationController
  before_action :authenticate_artisan!

  def index
    notifications = current_artisan.notifications.order(created_at: :desc)
    
    notifications_with_links = notifications.map do |n|
      besoin_id = n.besoin_id

      # Construire un lien cohérent, priorisant /annonces/#{besoin_id}
      link = if besoin_id.present?
               "/annonces/#{besoin_id}"
             elsif n.link.present?
               # Si le lien commence par /artisan/besoins, remplacer
               if n.link.start_with?('/artisan/besoins')
                 n.link.sub('/artisan/besoins', '/annonces')
               else
                 n.link
               end
             else
               '/annonces'
             end

      # Ajouter link et besoin_id dans l'objet JSON envoyé au front
      n.attributes.merge('link' => link, 'besoin_id' => besoin_id)
    end

    render json: notifications_with_links
  end

  def mark_as_read
    notification = current_artisan.notifications.find(params[:id])
    if notification.update(read: true)
      render json: { success: true, notification: notification }
    else
      render json: { success: false, errors: notification.errors.full_messages }, status: :unprocessable_entity
    end
  end
end








