module Artisans
  class AvailabilitySlotsController < ApplicationController
    before_action :authenticate_artisan!

    def index
      render json: current_artisan.availability_slots.order(:start_time)
    end

    def create
      slot = current_artisan.availability_slots.new(slot_params)
      if slot.save
        render json: slot, status: :created
      else
        render json: { errors: slot.errors.full_messages }, status: :unprocessable_entity
      end
    end

    def update
      slot = current_artisan.availability_slots.find(params[:id])
      if slot.update(slot_params)
        render json: slot
      else
        render json: { errors: slot.errors.full_messages }, status: :unprocessable_entity
      end
    end

    def destroy
      slot = current_artisan.availability_slots.find(params[:id])
      slot.destroy
      head :no_content
    end

    private

    def slot_params
      params.require(:availability_slot).permit(:start_time, :end_time)
    end
  end
end
