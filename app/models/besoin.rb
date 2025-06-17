class Besoin < ApplicationRecord
  belongs_to :client
  has_many_attached :images

  validates :type_prestation, :description, :schedule, :address, presence: true
  validates :description, length: { minimum: 30 }

  # Pour l’API JSON : inclure les URLs des images si besoin
  def image_urls
    images.map { |img| Rails.application.routes.url_helpers.rails_blob_url(img, host: ENV.fetch("HOST_URL", "http://localhost:3001")) }
  end
end
