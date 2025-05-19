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
          insurance_url: artisan.insurance.attached? ? url_for(artisan.insurance) : nil
        }
      }, status: :ok
    end

    def update
      artisan = current_artisan
      previous_plan = artisan.membership_plan

      permitted_params = params.require(:artisan).permit(
        :company_name, :address, :expertise, :siren,
        :email, :phone, :password, :password_confirmation, :membership_plan,
        :kbis, :insurance
      )

      if permitted_params[:kbis]
        artisan.kbis.attach(permitted_params[:kbis])
      end

      if permitted_params[:insurance]
        artisan.insurance.attach(permitted_params[:insurance])
      end

      artisan_params = permitted_params.except(:kbis, :insurance)

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
              :email, :phone, :membership_plan
            ]).merge({
              kbis_url: artisan.kbis.attached? ? url_for(artisan.kbis) : nil,
              insurance_url: artisan.insurance.attached? ? url_for(artisan.insurance) : nil
            })
          }
        end
      else
        render json: { errors: artisan.errors.full_messages }, status: :unprocessable_entity
      end
    end

    def destroy
      artisan = current_artisan
      artisan.destroy
      head :no_content
    end

    # Nouvelle action pour récupérer prix + fréquence Stripe
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





