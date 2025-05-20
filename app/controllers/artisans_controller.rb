class ArtisansController < ApplicationController
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

    render json: artisans
  end
end
