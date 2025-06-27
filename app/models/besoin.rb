class Besoin < ApplicationRecord
  belongs_to :client

  has_many_attached :images

  validates :type_prestation, :description, :schedule, :address, presence: true
  validates :description, length: { minimum: 30 }

  def image_urls
    return [] unless images.attached?

    images.map { |img| Rails.application.routes.url_helpers.url_for(img) }
  end
end
