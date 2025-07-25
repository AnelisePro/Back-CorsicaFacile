module Clients
  class ConversationsController < ApplicationController
    before_action :authenticate_client!

    def index
      conversations = current_client.conversations.active.includes(:artisan, :messages)
      
      conversations_data = conversations.map do |conversation|
        last_message = conversation.last_message
        unread_count = conversation.unread_messages_count_for(current_client)
        
        # Récupérer l'URL de l'avatar de l'artisan
        artisan_avatar_url = nil
        if conversation.artisan.avatar.attached?
          artisan_avatar_url = Rails.application.routes.url_helpers.rails_blob_url(
            conversation.artisan.avatar,
            host: request.base_url
          )
        end
        
        {
          id: conversation.id,
          other_user_id: conversation.artisan.id,
          other_user_name: conversation.artisan.company_name,
          other_user_type: 'Artisan',
          other_user_avatar: artisan_avatar_url,
          last_message: last_message&.content || 'Aucun message',
          last_message_at: last_message&.created_at || conversation.created_at,
          unread_count: unread_count
        }
      end
      
      render json: conversations_data
    end

    def create
      artisan = Artisan.find(params[:artisan_id])
      
      # Vérifier si une conversation existe déjà
      conversation = current_client.conversations.find_by(artisan: artisan)
      
      if conversation.nil?
        conversation = current_client.conversations.create!(artisan: artisan)
      end
      
      render json: { id: conversation.id, status: 'created' }
    end

    def show
      conversation = current_client.conversations.find(params[:id])
      messages = conversation.messages.includes(:sender).order(:created_at)
      
      # Marquer comme lu automatiquement
      conversation.messages.where(
        sender_type: 'Artisan',
        read: false
      ).update_all(read: true)
      
      messages_data = messages.map do |message|
        # Récupérer l'URL de l'avatar du sender
        sender_avatar_url = nil
        if message.sender.avatar.attached?
          sender_avatar_url = Rails.application.routes.url_helpers.rails_blob_url(
            message.sender.avatar,
            host: request.base_url
          )
        end
        
        {
          id: message.id,
          content: message.content,
          sender_id: message.sender_id,
          sender_type: message.sender_type,
          recipient_id: message.recipient_id,
          recipient_type: message.recipient_type,
          sender_name: message.sender_type == 'Client' ? 
            "#{message.sender.first_name} #{message.sender.last_name}" : 
            message.sender.company_name,
          sender_avatar: sender_avatar_url,
          created_at: message.created_at.iso8601,
          read: message.read
        }
      end
      
      render json: messages_data
    end

    def send_message
      conversation = current_client.conversations.find(params[:id])
      
      message = conversation.messages.build(message_params.merge(
        sender: current_client,
        recipient: conversation.artisan
      ))
      
      if message.save
        render json: {
          id: message.id,
          content: message.content,
          sender_id: message.sender_id,
          sender_type: message.sender_type,
          recipient_id: message.recipient_id,
          recipient_type: message.recipient_type,
          sender_name: "#{current_client.first_name} #{current_client.last_name}",
          sender_avatar: current_client.avatar,
          created_at: message.created_at.iso8601,
          read: message.read
        }, status: :created
      else
        render json: { errors: message.errors.full_messages }, status: :unprocessable_entity
      end
    end

    def mark_as_read
      conversation = current_client.conversations.find(params[:id])
      
      # Marquer tous les messages de l'artisan comme lus
      conversation.messages.where(
        sender_type: 'Artisan',
        read: false
      ).update_all(read: true)
      
      render json: { status: 'marked_as_read' }
    end

    def archive
      conversation = current_client.conversations.find(params[:id])
      if conversation.update(archived: true)
        render json: { status: 'archived', message: 'Conversation archivée avec succès' }
      else
        render json: { error: 'Impossible d\'archiver la conversation' }, status: :unprocessable_entity
      end
    end

    def archived
      archived_conversations = current_client.conversations.archived.includes(:artisan, :messages)
      
      conversations_data = archived_conversations.map do |conversation|
        last_message = conversation.last_message
        {
          id: conversation.id,
          other_user_id: conversation.artisan.id,
          other_user_name: conversation.artisan.company_name,
          other_user_type: 'Artisan',
          other_user_avatar: conversation.artisan.avatar,
          last_message: last_message&.content || 'Aucun message',
          last_message_at: last_message&.created_at || conversation.created_at,
          unread_count: 0
        }
      end

      render json: conversations_data
    end

    def unarchive
      conversation = current_client.conversations.find(params[:id])
      if conversation.update(archived: false)
        render json: { status: 'unarchived', message: 'Conversation désarchivée avec succès' }
      else
        render json: { error: 'Impossible de désarchiver la conversation' }, status: :unprocessable_entity
      end
    end

    def destroy
      # Ne filtrez pas les conversations archivées pour la suppression
      conversation = current_client.conversations.unscoped.find_by(id: params[:id], client_id: current_client.id)
      
      if conversation.nil?
        render json: { error: 'Conversation non trouvée' }, status: :not_found
        return
      end
      
      conversation.destroy
      render json: { status: 'deleted', message: 'Conversation supprimée avec succès' }
    end

    private

    def message_params
      params.require(:message).permit(:content)
    end
  end
end



