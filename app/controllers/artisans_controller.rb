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

      # ✅ Trouver les IDs d'artisans
      artisan_ids = Artisan.joins(:expertises)
                          .where("expertises.name ILIKE ?", "%#{sanitized_expertise}%")
                          .where("artisans.address ILIKE ?", "%#{sanitized_location}%")
                          .distinct
                          .pluck(:id)

      # 🚀 Charger tout d'un coup avec includes optimisé
      artisans = Artisan.includes(:reviews, :expertises, avatar_attachment: :blob)
                       .where(id: artisan_ids)
                       .order(Arel.sql(<<~SQL))
                         CASE membership_plan
                           WHEN 'Premium' THEN 0
                           WHEN 'Pro' THEN 1
                           WHEN 'Standard' THEN 2
                           ELSE 3
                         END ASC
                       SQL
    else
      artisans = Artisan.none
    end

    # 🚀 Optimisation : calculer les reviews en une fois
    artisans_data = artisans.map do |artisan|
      reviews = artisan.reviews.loaded? ? artisan.reviews : artisan.reviews.to_a
      
      Rails.logger.info("🔍 Artisan: #{artisan.company_name} - Reviews: #{reviews.count}")
      
      if reviews.any?
        # 🚀 Calculer directement sur le tableau chargé
        ratings = reviews.map(&:rating)
        average_rating = (ratings.sum.to_f / ratings.count).round(1)
        total_reviews = reviews.count
        Rails.logger.info("🔍 #{artisan.company_name}: avg=#{average_rating}, total=#{total_reviews}")
      else
        average_rating = 0.0
        total_reviews = 0
      end

      # 🚀 Avatar URL optimisé
      avatar_url = if artisan.avatar.attached?
        begin
          url_for(artisan.avatar)
        rescue => e
          Rails.logger.error "Erreur avatar pour #{artisan.company_name}: #{e.message}"
          nil
        end
      else
        nil
      end

      {
        id: artisan.id,
        company_name: artisan.company_name,
        address: artisan.address,
        description: artisan.description,
        membership_plan: artisan.membership_plan,
        expertise_names: artisan.expertises.map(&:name), # 🚀 Déjà chargé
        avatar_url: avatar_url,
        average_rating: average_rating,
        total_reviews: total_reviews
      }
    end

    render json: artisans_data
  end

  def show
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
    @artisan = Artisan.includes(:reviews).find_by(id: params[:id])
    unless @artisan
      render json: { error: "Artisan introuvable" }, status: :not_found
    end
  end
end









