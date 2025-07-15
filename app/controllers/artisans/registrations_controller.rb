module Artisans
  class RegistrationsController < Devise::RegistrationsController
    respond_to :json

    def create
      form_data = sign_up_params
      membership_plan = form_data[:membership_plan]
      expertise_name = form_data.delete(:expertise)

      @artisan = Artisan.new(form_data)
      @artisan.subscription_started_at = Time.current

      frontend_url = ENV['FRONTEND_URL'] || 'http://localhost:3000'

      ActiveRecord::Base.transaction do
        # Sauvegarde artisan sans expertise
        @artisan.save!

        # Trouve ou crée l'expertise
        expertise = Expertise.find_or_create_by!(name: expertise_name)

        # Associe l'expertise à l'artisan (en mémoire)
        @artisan.expertises << expertise

        # Sauvegarde à nouveau pour valider l’association
        @artisan.save!

        prices = {
          'Standard' => 'price_1RO49eRs43niZdSJXoxviAQo',
          'Pro' => 'price_1RO49tRs43niZdSJkubGXybT',
          'Premium' => 'price_1RO4A9Rs43niZdSJTEnzSTMt'
        }

        price_id = prices[membership_plan]

        unless price_id
          raise ActiveRecord::Rollback, 'Formule invalide'
        end

        session = Stripe::Checkout::Session.create(
          payment_method_types: ['card'],
          line_items: [{
            price: price_id,
            quantity: 1
          }],
          mode: 'subscription',
          customer_email: @artisan.email,
          success_url: "#{frontend_url}/auth/login_artisan?payment=success&session_id={CHECKOUT_SESSION_ID}",
          cancel_url: "#{frontend_url}/",
          metadata: {
            artisan_id: @artisan.id,
            membership_plan: membership_plan
          }
        )

        render json: { session_id: session.id, message: 'Artisan créé, redirection vers paiement' }, status: :ok
      end
    rescue ActiveRecord::RecordInvalid => e
      render json: { errors: e.record.errors.full_messages }, status: :unprocessable_entity
    rescue ActiveRecord::Rollback
      @artisan.destroy if @artisan.persisted?
      render json: { error: 'Formule invalide' }, status: :unprocessable_entity
    end

    private

    def sign_up_params
      params.require(:artisan).permit(
        :company_name, :address, :expertise, :siren,
        :kbis_url, :insurance_url, :email, :phone, :membership_plan,
        :password, :password_confirmation
      )
    end
  end
end







