class ArtisanExpertise < ApplicationRecord
  belongs_to :artisan
  belongs_to :expertise

  validates :expertise_id, uniqueness: { scope: :artisan_id }
end