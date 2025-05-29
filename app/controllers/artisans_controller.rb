class ArtisansController < ApplicationController
  include Rails.application.routes.url_helpers

  # GET /artisans
  def index
    expertise = params[:expertise]
    location = params[:location]

    if expertise.present? && location.present?
      sanitized_location = ActiveRecord::Base.sanitize_sql_like(location)
      artisans = Artisan.where(expertise: expertise)
                        .where("address ILIKE ?", "%#{sanitized_location}%")
    else
      artisans = Artisan.none
    end

    render json: artisans.map { |artisan|
      artisan.as_json(only: [:id, :company_name, :address, :expertise, :description]).merge({
        avatar_url: artisan.avatar.attached? ? url_for(artisan.avatar) : nil
      })
    }
  end

  # GET /artisans/:id
  def show
    artisan = Artisan.find(params[:id])
    host = request.base_url

    render json: artisan.as_json(
      only: [:id, :company_name, :address, :expertise, :description]
    ).merge(
      avatar_url: artisan.avatar.attached? ? url_for(artisan.avatar) : nil,
      images_urls: artisan.project_images.map { |img| url_for(img) },
      availability_slots: artisan.availability_slots.map do |slot|
      {
        id: slot.id,
        start_time: slot.start_time,
        end_time: slot.end_time
      }
    end
    )
  end
end






