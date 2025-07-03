class AnnoncesController < ApplicationController
  before_action :authenticate_artisan!

  def show
    besoin = Besoin.find_by(id: params[:id])
    if besoin
      render json: besoin, include: { client: { only: [:id, :first_name, :last_name, :email, :phone] } }
    else
      render json: { error: 'Annonce non trouvée' }, status: :not_found
    end
  end
end
