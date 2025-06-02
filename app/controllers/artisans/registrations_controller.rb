module Artisans
  class RegistrationsController < Devise::RegistrationsController
    respond_to :json

    def create
      form_data = sign_up_params
      membership_plan = form_data[:membership_plan]
      expertise_name = form_data.delete(:expertise)

      @artisan = Artisan.new(form_data.except(:kbis, :insurance))

      # Attacher les fichiers AVANT de sauvegarder pour que validations passent
      @artisan.kbis.attach(form_data[:kbis]) if form_data[:kbis].present?
      @artisan.insurance.attach(form_data[:insurance]) if form_data[:insurance].present?

      ActiveRecord::Base.transaction do
        # Sauvegarde artisan sans expertise
        @artisan.save!

        # Trouve ou crée l'expertise
        expertise = Expertise.find_or_create_by!(name: expertise_name)

        # Associe l'expertise à l'artisan, sans sauvegarder encore (association en mémoire)
        @artisan.expertises << expertise

        # Sauvegarde l’artisan à nouveau, maintenant avec expertise associée
        # On passe skip_validate_expertises pour contourner la validation au premier save
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
          success_url: "http://localhost:3000/auth/login_artisan?payment=success&session_id={CHECKOUT_SESSION_ID}",
          cancel_url: "http://localhost:3000/",
          metadata: {
            artisan_id: @artisan.id
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
        :kbis, :insurance, :email, :phone, :membership_plan,
        :password, :password_confirmation
      )
    end
  end
end






