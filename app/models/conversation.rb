class Conversation < ApplicationRecord
  belongs_to :client
  belongs_to :artisan
  has_many :messages, dependent: :destroy
  
  validates :client_id, uniqueness: { scope: :artisan_id }
  
  def last_message
    messages.order(:created_at).last
  end
  
  def unread_messages_count_for(user)
    messages.where(recipient: user, read: false).count
  end
  
  def other_participant(current_user)
    current_user.is_a?(Client) ? artisan : client
  end
end
