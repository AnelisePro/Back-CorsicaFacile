module Artisans
  class ConversationsController < ApplicationController
    before_action :authenticate_artisan!

    def index
      conversations = current_artisan.conversations.includes(:client)
      
      conversations_data = conversations.map do |conversation|
        last_message = conversation.messages.last
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

    def show
      conversation = current_artisan.conversations.find(params[:id])
      messages = conversation.messages.order(:created_at)
      
      # Marquer comme lu automatiquement
      conversation.messages.where(
        sender_type: 'Client',
        read: false
      ).update_all(read: true)
      
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
      conversation = current_artisan.conversations.find(params[:id])
      
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
      conversation = current_artisan.conversations.find(params[:id])
      
      conversation.messages.where(
        sender_type: 'Client',
        read: false
      ).update_all(read: true)
      
      render json: { status: 'marked_as_read' }
    end

    private

    def message_params
      params.require(:message).permit(:content)
    end
  end
end




