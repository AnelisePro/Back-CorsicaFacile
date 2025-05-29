module Artisans
  class ProfilesController < ApplicationController
    before_action :authenticate_artisan!

    def show
      artisan = current_artisan

      render json: {
        artisan: {
          company_name: artisan.company_name,
          address: artisan.address,
          expertise: artisan.expertise,
          siren: artisan.siren,
          email: artisan.email,
          phone: artisan.phone,
          membership_plan: artisan.membership_plan,
          kbis_url: artisan.kbis.attached? ? url_for(artisan.kbis) : nil,
          insurance_url: artisan.insurance.attached? ? url_for(artisan.insurance) : nil,
          avatar_url: artisan.avatar.attached? ? url_for(artisan.avatar) : nil,
          description: artisan.description,
          images_urls: artisan.project_images.map { |img| url_for(img) },
        }
      }, status: :ok
    end

    def update
      artisan = current_artisan
      previous_plan = artisan.membership_plan

      permitted_params = params.require(:artisan).permit(
        :company_name, :address, :expertise, :siren,
        :email, :phone, :password, :password_confirmation, :membership_plan,
        :kbis, :insurance, :avatar, :description, project_images: [],
        deleted_image_urls: []
      )

      # Suppression des images envoyées en deleted_image_urls
      if permitted_params[:deleted_image_urls].present?
        permitted_params[:deleted_image_urls].each do |url|
          image = artisan.project_images.find do |img|
            Rails.application.routes.url_helpers.rails_blob_url(img, only_path: false) == url
          end
          image&.purge
        end
      end

      artisan.kbis.attach(permitted_params[:kbis]) if permitted_params[:kbis]
      artisan.insurance.attach(permitted_params[:insurance]) if permitted_params[:insurance]
      artisan.avatar.attach(permitted_params[:avatar]) if permitted_params[:avatar]

      if permitted_params[:project_images]
        existing_images_count = artisan.project_images.count
        new_images_count = permitted_params[:project_images].size

        if existing_images_count + new_images_count > 10
          render json: { error: "Vous ne pouvez pas avoir plus de 10 images au total." }, status: :unprocessable_entity
          return
        end

        artisan.project_images.attach(permitted_params[:project_images])
      end

      # On prépare les params à mettre à jour (sans les fichiers et images)
      artisan_params = permitted_params.except(:kbis, :insurance, :avatar, :project_images, :deleted_image_urls)

      if artisan.update(artisan_params)
        if artisan.membership_plan != previous_plan
          prices = {
            'Standard' => 'price_1RO49eRs43niZdSJXoxviAQo',
            'Pro' => 'price_1RO49tRs43niZdSJkubGXybT',
            'Premium' => 'price_1RO4A9Rs43niZdSJTEnzSTMt'
          }

          price_id = prices[artisan.membership_plan]

          session = Stripe::Checkout::Session.create(
            payment_method_types: ['card'],
            line_items: [{ price: price_id, quantity: 1 }],
            mode: 'subscription',
            customer_email: artisan.email,
            success_url: "http://localhost:3000/auth/login_artisan?payment=success&session_id={CHECKOUT_SESSION_ID}",
            cancel_url: "http://localhost:3000/",
            metadata: {
              artisan_id: artisan.id,
              membership_plan: artisan.membership_plan
            }
          )

          render json: { checkout_url: session.url }
        else
          render json: {
            artisan: artisan.as_json(only: [
              :company_name, :address, :expertise, :siren,
              :email, :phone, :membership_plan, :description
            ]).merge({
              kbis_url: artisan.kbis.attached? ? url_for(artisan.kbis) : nil,
              insurance_url: artisan.insurance.attached? ? url_for(artisan.insurance) : nil,
              avatar_url: artisan.avatar.attached? ? url_for(artisan.avatar) : nil,
              images_urls: artisan.project_images.map { |img| url_for(img) },
            })
          }
        end
      else
        render json: { errors: artisan.errors.full_messages }, status: :unprocessable_entity
      end
    end

    def delete_project_image
      artisan = current_artisan
      image_id = params[:image_id]

      image = artisan.project_images.find_by(id: image_id)
      if image
        image.purge
        render json: { message: 'Image supprimée' }, status: :ok
      else
        render json: { error: 'Image introuvable' }, status: :not_found
      end
    end

    def destroy
      artisan = current_artisan
      artisan.destroy
      head :no_content
    end

    def plan_info
      prices = {
        'Standard' => 'price_1RO49eRs43niZdSJXoxviAQo',
        'Pro' => 'price_1RO49tRs43niZdSJkubGXybT',
        'Premium' => 'price_1RO4A9Rs43niZdSJTEnzSTMt'
      }

      price_id = prices[current_artisan.membership_plan]

      if price_id.nil?
        render json: { error: 'Plan invalide' }, status: :unprocessable_entity
        return
      end

      price = Stripe::Price.retrieve(price_id)

      price_info = {
        amount: price.unit_amount,
        currency: price.currency,
        interval: price.recurring&.interval || 'one_time'
      }

      render json: { price_info: price_info }, status: :ok
    end
  end
end

