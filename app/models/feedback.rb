class Feedback < ApplicationRecord
  belongs_to :user, polymorphic: true
  
  validates :title, presence: true, length: { minimum: 5, maximum: 100 }
  validates :content, presence: true, length: { minimum: 10, maximum: 1000 }
  validates :user_type, inclusion: { in: %w[Client Artisan] }
  
  enum status: { pending: 'pending', responded: 'responded', archived: 'archived' }
  
  scope :recent, -> { order(created_at: :desc) }
  scope :pending, -> { where(status: 'pending') }
  scope :public_display, -> { where(status: 'responded') }
end