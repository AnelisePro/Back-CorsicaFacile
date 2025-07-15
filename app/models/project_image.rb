class ProjectImage < ApplicationRecord
  belongs_to :artisan
  has_one_attached :image

  validates :image, presence: true
end
