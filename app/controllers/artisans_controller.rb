class ArtisansController < ApplicationController
  include Rails.application.routes.url_helpers

  before_action :set_artisan, only: [:show]

  def index
    expertise = params[:expertise]
    location = params[:location]

    Rails.logger.info("Recherche artisans pour expertise=#{expertise.inspect} et location=#{location.inspect}")

    if expertise.present? && location.present?
      sanitized_location = ActiveRecord::Base.sanitize_sql_like(location)
      sanitized_expertise = ActiveRecord::Base.sanitize_sql_like(expertise)

      # ✨ Inclure les reviews pour éviter N+1 queries
      artisans = Artisan.joins(:expertises)
                  .includes(:reviews)  # ← Ajout important
                  .where("expertises.name ILIKE ?", "%#{sanitized_expertise}%")
                  .where("artisans.address ILIKE ?", "%#{sanitized_location}%")
                  .distinct
    else
      artisans = Artisan.none
    end

    # 🚀 Enrichir avec les statistiques de reviews
    render json: artisans.map { |artisan|
      # Récupérer les reviews de l'artisan
      reviews = artisan.reviews
      
      # Debug pour vérifier
      Rails.logger.info("🔍 Artisan: #{artisan.company_name} - Reviews: #{reviews.count}")
      
      # Calculer les statistiques
      if reviews.any?
        average_rating = reviews.average(:rating).to_f.round(1)
        total_reviews = reviews.count
        Rails.logger.info("🔍 #{artisan.company_name}: avg=#{average_rating}, total=#{total_reviews}")
      else
        average_rating = 0.0
        total_reviews = 0
      end

      # Construire la réponse
      artisan.as_json(
        only: [:id, :company_name, :address, :description, :membership_plan]
      ).merge({
        expertise_names: artisan.expertises.pluck(:name),
        avatar_url: artisan.avatar.attached? ? url_for(artisan.avatar) : nil,
        # ✨ Nouvelles données pour les reviews
        average_rating: average_rating,
        total_reviews: total_reviews
      })
    }
  end

  def show
    # ✨ Enrichir aussi la vue détail avec les stats de reviews
    reviews = @artisan.reviews
    average_rating = reviews.any? ? reviews.average(:rating).to_f.round(1) : 0.0
    total_reviews = reviews.count

    render json: @artisan.as_json(
      only: [
        :id,
        :company_name,
        :address,
        :description,
        :email,
        :phone,
        :membership_plan
      ]
    ).merge(
      avatar_url: @artisan.avatar.attached? ? url_for(@artisan.avatar) : nil,
      expertise_names: @artisan.expertises.pluck(:name),
      # ✨ Stats de reviews
      average_rating: average_rating,
      total_reviews: total_reviews,
      availability_slots: @artisan.availability_slots.map do |slot|
        {
          id: slot.id,
          start_time: slot.start_time,
          end_time: slot.end_time
        }
      end,
      project_images: @artisan.project_images.map do |image|
        {
          id: image.id,
          image_url: url_for(image.image)
        }
      end
    )
  end

  private

  def set_artisan
    @artisan = Artisan.includes(:reviews).find_by(id: params[:id])  # ← Inclure les reviews
    unless @artisan
      render json: { error: "Artisan introuvable" }, status: :not_found
    end
  end
end










