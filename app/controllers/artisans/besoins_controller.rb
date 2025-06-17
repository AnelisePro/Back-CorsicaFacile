class Artisans::BesoinsController < ApplicationController
  before_action :authenticate_artisan!

  def index
    besoins = Besoin.with_attached_images.includes(:client).all
    render json: besoins.as_json(
      methods: :image_urls,
      include: { client: { only: [:id, :first_name, :last_name, :email, :phone] } }
    )
  end
end
