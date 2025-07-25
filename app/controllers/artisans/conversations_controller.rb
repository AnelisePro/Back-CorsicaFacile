module Artisans
  class ConversationsController < ApplicationController
    before_action :authenticate_artisan!

    def index
      # Récupérer seulement les conversations actives (non archivées)
      conversations = current_artisan.conversations.where(archived: [false, nil]).includes(:client, :messages)
      
      conversations_data = conversations.map do |conversation|
        last_message = conversation.messages.order(:created_at).last
        unread_count = conversation.messages.where(
          sender_type: 'Client',
          read: false
        ).count
        
        {
          id: conversation.id,
          other_user_id: conversation.client.id,
          other_user_name: "#{conversation.client.first_name} #{conversation.client.last_name}",
          other_user_type: 'Client',
          last_message: last_message&.content || 'Aucun message',
          last_message_at: last_message&.created_at || conversation.created_at,
          unread_count: unread_count
        }
      end
      
      render json: conversations_data
    end

    def archived
      # Nouvelle méthode pour récupérer les conversations archivées
      conversations = current_artisan.conversations.where(archived: true).includes(:client, :messages)
      
      conversations_data = conversations.map do |conversation|
        last_message = conversation.messages.order(:created_at).last
        unread_count = conversation.messages.where(
          sender_type: 'Client',
          read: false
        ).count
        
        {
          id: conversation.id,
          other_user_id: conversation.client.id,
          other_user_name: "#{conversation.client.first_name} #{conversation.client.last_name}",
          other_user_type: 'Client',
          last_message: last_message&.content || 'Aucun message',
          last_message_at: last_message&.created_at || conversation.created_at,
          unread_count: unread_count,
          archived: true
        }
      end
      
      render json: conversations_data
    end

    def show
      # Utiliser find_by pour une meilleure gestion d'erreur
      conversation = current_artisan.conversations.find_by(id: params[:id])
      
      if conversation.nil?
        render json: { error: 'Conversation non trouvée' }, status: :not_found
        return
      end

      messages = conversation.messages.includes(:sender).order(:created_at)
      
      # Marquer comme lu automatiquement seulement si la conversation n'est pas archivée
      unless conversation.archived?
        conversation.messages.where(
          sender_type: 'Client',
          read: false
        ).update_all(read: true)
      end
      
      messages_data = messages.map do |message|
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
          created_at: message.created_at.iso8601,
          read: message.read
        }
      end
      
      render json: messages_data
    end

    def send_message
      conversation = current_artisan.conversations.find_by(id: params[:id])
      
      if conversation.nil?
        render json: { error: 'Conversation non trouvée' }, status: :not_found
        return
      end

      # Empêcher l'envoi de messages dans les conversations archivées
      if conversation.archived?
        render json: { error: 'Impossible d\'envoyer un message dans une conversation archivée' }, status: :forbidden
        return
      end
      
      message = conversation.messages.build(message_params.merge(
        sender: current_artisan,
        recipient: conversation.client
      ))
      
      if message.save
        render json: {
          id: message.id,
          content: message.content,
          sender_id: message.sender_id,
          sender_type: message.sender_type,
          recipient_id: message.recipient_id,
          recipient_type: message.recipient_type,
          sender_name: current_artisan.company_name,
          created_at: message.created_at.iso8601,
          read: message.read
        }, status: :created
      else
        render json: { errors: message.errors.full_messages }, status: :unprocessable_entity
      end
    end

    def mark_as_read
      conversation = current_artisan.conversations.find_by(id: params[:id])
      
      if conversation.nil?
        render json: { error: 'Conversation non trouvée' }, status: :not_found
        return
      end
      
      # Marquer tous les messages du client comme lus
      conversation.messages.where(
        sender_type: 'Client',
        read: false
      ).update_all(read: true)
      
      render json: { status: 'marked_as_read' }
    end

    def archive
      # Utiliser find_by au lieu de find pour éviter les exceptions
      conversation = Conversation.find_by(id: params[:id], artisan_id: current_artisan.id)
      
      if conversation.nil?
        render json: { error: 'Conversation non trouvée' }, status: :not_found
        return
      end
      
      if conversation.update(archived: true)
        render json: { status: 'archived', message: 'Conversation archivée avec succès' }
      else
        render json: { error: 'Impossible d\'archiver la conversation' }, status: :unprocessable_entity
      end
    end

    def unarchive
      # Nouvelle méthode pour désarchiver
      conversation = Conversation.find_by(id: params[:id], artisan_id: current_artisan.id)
      
      if conversation.nil?
        render json: { error: 'Conversation non trouvée' }, status: :not_found
        return
      end
      
      if conversation.update(archived: false)
        render json: { status: 'unarchived', message: 'Conversation désarchivée avec succès' }
      else
        render json: { error: 'Impossible de désarchiver la conversation' }, status: :unprocessable_entity
      end
    end

    def destroy
      # Utiliser une requête directe pour éviter les problèmes de scope
      conversation = Conversation.find_by(id: params[:id], artisan_id: current_artisan.id)
      
      if conversation.nil?
        render json: { error: 'Conversation non trouvée ou non autorisée' }, status: :not_found
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





