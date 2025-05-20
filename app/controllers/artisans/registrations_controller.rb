module Artisans
  class RegistrationsController < Devise::RegistrationsController
    respond_to :json

    def create
      form_data = sign_up_params
      membership_plan = form_data[:membership_plan]

      @artisan = Artisan.new(form_data.except(:kbis, :insurance))

      @artisan.kbis.attach(form_data[:kbis]) if form_data[:kbis].present?
      @artisan.insurance.attach(form_data[:insurance]) if form_data[:insurance].present?

      if @artisan.save
        prices = {
          'Standard' => 'price_1RO49eRs43niZdSJXoxviAQo',
          'Pro' => 'price_1RO49tRs43niZdSJkubGXybT',
          'Premium' => 'price_1RO4A9Rs43niZdSJTEnzSTMt'
        }

        price_id = prices[membership_plan]

        unless price_id
          @artisan.destroy
          return render json: { error: 'Formule invalide' }, status: :unprocessable_entity
        end

        session = Stripe::Checkout::Session.create(
          payment_method_types: ['card'],
          line_items: [{
            price: price_id,
            quantity: 1
          }],
          mode: 'subscription',
          customer_email: @artisan.email,
          success_url: "http://localhost:3000/auth/login_artisan?payment=success&session_id={CHECKOUT_SESSION_ID}",
          cancel_url: "http://localhost:3000/",
          metadata: {
            artisan_id: @artisan.id
          }
        )

        render json: { session_id: session.id, message: 'Artisan créé, redirection vers paiement' }, status: :ok
      else
        render json: { errors: @artisan.errors.full_messages }, status: :unprocessable_entity
      end
    end

    private

    def sign_up_params
      params.require(:artisan).permit(
        :company_name, :address, :expertise, :siren,
        :kbis, :insurance, :email, :phone, :membership_plan,
        :password, :password_confirmation
      )
    end
  end
end




