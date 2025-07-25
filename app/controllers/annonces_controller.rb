class AnnoncesController < ApplicationController
  before_action :authenticate_artisan!

  def show
    besoin = Besoin.find_by(id: params[:id])
    if besoin
      response_data = besoin.as_json(
        methods: [:image_urls, :parsed_schedule],
        include: { client: { only: [:id, :first_name, :last_name, :email, :phone] } }
      )
      
      render json: format_besoin_response(response_data)
    else
      render json: { error: 'Annonce non trouvée' }, status: :not_found
    end
  end

  private

  def format_besoin_response(besoin_data)
    # Remplacer le schedule string par l'objet parsé
    if besoin_data['parsed_schedule']
      besoin_data['schedule'] = besoin_data['parsed_schedule']
      besoin_data.delete('parsed_schedule')
    end
    besoin_data
  end
end
