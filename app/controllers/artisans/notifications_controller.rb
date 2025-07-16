module Artisans
  class NotificationsController < ApplicationController
    before_action :authenticate_artisan!

    def index
      notifications = current_artisan.notifications.order(created_at: :desc)
      unread_count = notifications.where(read: false).count

      notifications_with_links = notifications.map do |n|
        besoin_id = n.besoin_id
        link = build_notification_link(n, besoin_id)

        {
          id: n.id,
          message: n.message,
          read: n.read,
          created_at: n.created_at,
          status: n.status,
          besoin_id: besoin_id,
          link: link
        }
      end

      render json: {
        success: true,
        notifications: notifications_with_links,
        unread_count: unread_count
      }
    end

    def mark_as_read
      notification = current_artisan.notifications.find(params[:id])
      if notification.update(read: true)
        unread_count = current_artisan.notifications.where(read: false).count
        render json: {
          success: true,
          notification: notification,
          unread_count: unread_count
        }
      else
        render json: {
          success: false,
          errors: notification.errors.full_messages
        }, status: :unprocessable_entity
      end
    end

    def destroy
      notification = current_artisan.notifications.find(params[:id])

      if notification.destroy
        unread_count = current_artisan.notifications.where(read: false).count
        render json: {
          success: true,
          message: 'Notification supprimée avec succès',
          unread_count: unread_count
        }
      else
        render json: {
          success: false,
          errors: notification.errors.full_messages
        }, status: :unprocessable_entity
      end
    end

    private

    def build_notification_link(notification, besoin_id)
      if besoin_id.present?
        "/annonces/#{besoin_id}"
      elsif notification.link.present?
        notification.link.start_with?('/artisan/besoins') ?
          notification.link.sub('/artisan/besoins', '/annonces') :
          notification.link
      else
        '/annonces'
      end
    end
  end
end









