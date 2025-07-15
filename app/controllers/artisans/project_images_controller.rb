module Artisans
  class ProjectImagesController < ApplicationController
    before_action :authenticate_artisan!

    def index
      images = current_artisan.project_images.with_attached_image
      render json: images.map { |img| project_image_json(img) }, status: :ok
    end

    def create
      project_image = current_artisan.project_images.new
      project_image.image.attach(params[:image])

      if project_image.save
        render json: project_image_json(project_image), status: :created
      else
        render json: { errors: project_image.errors.full_messages }, status: :unprocessable_entity
      end
    end

    def destroy
      project_image = current_artisan.project_images.find(params[:id])
      project_image.destroy
      head :no_content
    end

    private

    def project_image_json(project_image)
      {
        id: project_image.id,
        image_url: url_for(project_image.image)
      }
    end
  end
end
