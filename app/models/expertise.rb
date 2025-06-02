class Expertise < ApplicationRecord
  validates :name, presence: true, uniqueness: true

  has_many :artisan_expertises
  has_many :artisans, through: :artisan_expertises
end