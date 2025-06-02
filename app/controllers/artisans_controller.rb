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

      artisans = Artisan.joins(:expertises)
                  .where("expertises.name ILIKE ?", "%#{sanitized_expertise}%")
                  .where("artisans.address ILIKE ?", "%#{sanitized_location}%")
                  .distinct
    else
      artisans = Artisan.none
    end

    render json: artisans.map { |artisan|
      artisan.as_json(only: [:id, :company_name, :address, :description]).merge({
        expertise_names: artisan.expertises.pluck(:name),
        avatar_url: artisan.avatar.attached? ? url_for(artisan.avatar) : nil
      })
    }
  end

  def show
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
      images_urls: @artisan.project_images.map { |img| url_for(img) },
      availability_slots: @artisan.availability_slots.map do |slot|
        {
          id: slot.id,
          start_time: slot.start_time,
          end_time: slot.end_time
        }
      end
    )
  end

  private

  def set_artisan
    @artisan = Artisan.find_by(id: params[:id])
    unless @artisan
      render json: { error: "Artisan introuvable" }, status: :not_found
    end
  end
end








