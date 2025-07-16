class Message < ApplicationRecord
  belongs_to :conversation
  belongs_to :sender, polymorphic: true
  belongs_to :recipient, polymorphic: true
  
  validates :content, presence: true
  
  scope :unread, -> { where(read: false) }
  scope :for_conversation, ->(conversation) { where(conversation: conversation) }
  
  after_create :update_conversation_timestamp
  
  private
  
  def update_conversation_timestamp
    conversation.touch
  end
end
