module Artisans
  class ProfilesController < ApplicationController
    before_action :authenticate_artisan!

    def show
      artisan = current_artisan

      # Récupération des informations du plan
      plan_info = get_plan_info(artisan.membership_plan)

      # Préparation des données de l'artisan
      artisan_data = {
        company_name: artisan.company_name,
        address: artisan.address,
        expertise_names: artisan.expertises.pluck(:name),
        siren: artisan.siren,
        email: artisan.email,
        phone: artisan.phone,
        membership_plan: artisan.membership_plan,
        kbis_url: artisan.kbis_url,
        insurance_url: artisan.insurance_url,
        avatar_url: artisan.avatar.attached? ? url_for(artisan.avatar) : nil,
        description: artisan.description,
        project_images_urls: get_project_images_urls(artisan)
      }

      render json: {
        artisan: artisan_data,
        plan_info: plan_info
      }, status: :ok
    end

    def update
      artisan = current_artisan
      previous_plan = artisan.membership_plan

      permitted_params = params.require(:artisan).permit(
        :company_name, :address, :siren, :email, :phone,
        :password, :password_confirmation, :membership_plan,
        :kbis_url, :insurance_url, :avatar, :description,
        expertise_names: [], project_images_urls: []
      )

      # Gestion des expertises
      expertise_names = permitted_params.delete(:expertise_names)
      artisan.expertises = Expertise.where(name: expertise_names) if expertise_names.present?

      # Gestion de l'avatar
      artisan.avatar.attach(permitted_params[:avatar]) if permitted_params[:avatar]

      # Mise à jour des attributs
      artisan_params = permitted_params.except(:avatar, :expertise_names, :project_images_urls)

      unless artisan.update(artisan_params)
        render json: { errors: artisan.errors.full_messages }, status: :unprocessable_entity
        return
      end

      if artisan.membership_plan != previous_plan
        session = create_stripe_session(artisan)
        render json: { checkout_url: session.url }
      else
        artisan_data = {
          company_name: artisan.company_name,
          address: artisan.address,
          expertise_names: artisan.expertises.pluck(:name),
          siren: artisan.siren,
          email: artisan.email,
          phone: artisan.phone,
          membership_plan: artisan.membership_plan,
          kbis_url: artisan.kbis_url,
          insurance_url: artisan.insurance_url,
          avatar_url: artisan.avatar.attached? ? url_for(artisan.avatar) : nil,
          description: artisan.description,
          project_images_urls: get_project_images_urls(artisan)
        }

        render json: { artisan: artisan_data }
      end
    end

    def destroy
      artisan_data = {
        company_name: current_artisan.company_name,
        email: current_artisan.email,
        membership_plan: current_artisan.membership_plan
      }
      
      # Envoyer l'email AVANT la suppression
      ArtisanMailer.account_deleted_email(current_artisan).deliver_now

      current_artisan.destroy
      head :no_content
    end

    def plan_info
      prices = {
        'Standard' => 'price_1RO49eRs43niZdSJXoxviAQo',
        'Pro' => 'price_1RO49tRs43niZdSJkubGXybT',
        'Premium' => 'price_1RO4A9Rs43niZdSJTEnzSTMt'
      }
      price_id = prices[current_artisan.membership_plan]
      return render json: { error: 'Plan invalide' }, status: :unprocessable_entity if price_id.nil?

      price = Stripe::Price.retrieve(price_id)

      render json: {
        price_info: {
          amount: price.unit_amount,
          currency: price.currency,
          interval: price.recurring&.interval || 'one_time'
        }
      }, status: :ok
    end

     private

    def get_plan_info(plan_name)
      prices = {
        'Standard' => 'price_1RO49eRs43niZdSJXoxviAQo',
        'Pro' => 'price_1RO49tRs43niZdSJkubGXybT',
        'Premium' => 'price_1RO4A9Rs43niZdSJTEnzSTMt'
      }

      return nil unless prices[plan_name]

      price = Stripe::Price.retrieve(prices[plan_name])
      {
        amount: price.unit_amount,
        currency: price.currency,
        interval: price.recurring&.interval || 'one_time'
      }
    end

    def get_project_images_urls(artisan)
      artisan.project_images.with_attached_image.map do |pi|
        url_for(pi.image) if pi.image.attached?
      end.compact
    end

    def create_stripe_session(artisan)
      prices = {
        'Standard' => 'price_1RO49eRs43niZdSJXoxviAQo',
        'Pro' => 'price_1RO49tRs43niZdSJkubGXybT',
        'Premium' => 'price_1RO4A9Rs43niZdSJTEnzSTMt'
      }

      price_id = prices[artisan.membership_plan]
      Stripe::Checkout::Session.create(
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
    end
  end
end







