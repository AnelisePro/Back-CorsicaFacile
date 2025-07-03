class Artisans::BesoinsController < ApplicationController
  before_action :authenticate_artisan!

  def index
    besoins = Besoin.includes(:client).all
    render json: besoins.as_json(
      methods: :image_urls,
      include: { client: { only: [:id, :first_name, :last_name, :email, :phone] } }
    )
  end

  def show
    besoin = Besoin.find(params[:id])
    render json: besoin.as_json(
      methods: :image_urls,
      include: { client: { only: [:id, :first_name, :last_name, :email, :phone] } }
    )
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Besoin non trouvé' }, status: :not_found
  end
end
