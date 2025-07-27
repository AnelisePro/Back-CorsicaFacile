class Review < ApplicationRecord
  belongs_to :client
  belongs_to :artisan
  belongs_to :client_notification

  validates :rating, presence: true, inclusion: { in: 1..5 }
  validates :comment, presence: true, length: { minimum: 10, maximum: 500 }
  validates :client_id, uniqueness: { scope: [:artisan_id, :client_notification_id], 
                                     message: "Vous avez déjà laissé un avis pour cette mission" }

  scope :recent, -> { order(created_at: :desc) }
  scope :by_rating, ->(rating) { where(rating: rating) if rating.present? }
end
