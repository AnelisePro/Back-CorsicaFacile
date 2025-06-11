class PaymentsController < ApplicationController
  def create_checkout_session
    artisan = current_artisan
    membership_plan = params[:membership_plan]
    frontend_url = ENV['FRONTEND_URL'] || 'http://localhost:3000'

    prices = {
      'Standard' => 'price_1RO49eRs43niZdSJXoxviAQo',
      'Pro' => 'price_1RO49tRs43niZdSJkubGXybT',
      'Premium' => 'price_1RO4A9Rs43niZdSJTEnzSTMt'
    }

    price_id = prices[membership_plan]

    unless price_id
      render json: { error: 'Formule invalide' }, status: :unprocessable_entity
      return
    end

    session = Stripe::Checkout::Session.create(
      payment_method_types: ['card'],
      line_items: [{ price: price_id, quantity: 1 }],
      mode: 'subscription',
      customer_email: artisan.email,
      success_url: "#{frontend_url}/auth/login_artisan?payment=success&session_id={CHECKOUT_SESSION_ID}",
      cancel_url: "#{frontend_url}/",
      metadata: {
        artisan_id: artisan.id,
        membership_plan: membership_plan
      }
    )

    render json: { id: session.id }
  end

  private

  def authenticate_artisan_from_token!
    token = request.headers['Authorization']&.split(' ')&.last
    unless token
      render json: { error: 'Token manquant' }, status: :unauthorized and return
    end

    artisan = Artisan.find_by(authentication_token: token)
    if artisan.nil?
      render json: { error: 'Token invalide' }, status: :unauthorized and return
    end

    sign_in(:artisan, artisan, store: false) # pour que current_artisan fonctionne
  end
end




