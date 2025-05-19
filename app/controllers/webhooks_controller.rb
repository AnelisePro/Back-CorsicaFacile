class WebhooksController < ApplicationController
  skip_before_action :verify_authenticity_token

  def stripe
    payload = request.body.read
    sig_header = request.env['HTTP_STRIPE_SIGNATURE']
    endpoint_secret = ENV['STRIPE_WEBHOOK_SECRET']

    begin
      event = Stripe::Webhook.construct_event(payload, sig_header, endpoint_secret)
    rescue JSON::ParserError => e
      Rails.logger.error "JSON parse error: #{e.message}"
      render json: { error: "Invalid payload" }, status: 400 and return
    rescue Stripe::SignatureVerificationError => e
      Rails.logger.error "Stripe signature verification failed: #{e.message}"
      render json: { error: "Invalid signature" }, status: 400 and return
    end

    case event.type
    when 'checkout.session.completed'
      session = event.data.object.with_indifferent_access
      handle_successful_checkout(session)
    when 'customer.subscription.deleted'
      subscription = event.data.object.with_indifferent_access
      handle_subscription_deleted(subscription)
    when 'invoice.payment_failed'
      invoice = event.data.object.with_indifferent_access
      handle_payment_failed(invoice)
    else
      Rails.logger.info "Unhandled Stripe event type: #{event.type}"
    end

    render json: { message: "Webhook reçu avec succès" }, status: :ok
  end

  private

  def handle_successful_checkout(session)
    Rails.logger.info "Webhook checkout.session.completed received: #{session.inspect}"

    customer_email = session[:customer_email]
    subscription_id = session[:subscription]
    customer_id = session[:customer]
    metadata = session[:metadata] || {}
    membership_plan = metadata['membership_plan']

    Rails.logger.info "Webhook checkout.session.completed for email: #{customer_email}, subscription_id: #{subscription_id}, plan: #{membership_plan}"

    artisan = Artisan.find_by(email: customer_email)
    unless artisan
      Rails.logger.warn "Artisan not found for email #{customer_email}"
      return
    end

    updated = artisan.update(
      stripe_customer_id: customer_id,
      stripe_subscription_id: subscription_id,
      membership_plan: membership_plan,
      verified: true
    )

    if updated
      Rails.logger.info "Artisan #{artisan.email} successfully updated."
    else
      Rails.logger.error "Failed to update artisan #{artisan.email}: #{artisan.errors.full_messages.join(', ')}"
    end
  end

  def handle_subscription_deleted(subscription)
    stripe_customer_id = subscription[:customer]

    Rails.logger.info "Webhook customer.subscription.deleted for stripe_customer_id: #{stripe_customer_id}"

    artisan = Artisan.find_by(stripe_customer_id: stripe_customer_id)
    unless artisan
      Rails.logger.warn "Artisan not found for stripe_customer_id #{stripe_customer_id}"
      return
    end

    artisan.update(
      stripe_subscription_id: nil,
      membership_plan: nil,
      verified: false
    )

    Rails.logger.info "Artisan #{artisan.email} subscription cancelled and account deactivated"
  end

  def handle_payment_failed(invoice)
    stripe_customer_id = invoice[:customer]

    Rails.logger.info "Webhook invoice.payment_failed for customer_id: #{stripe_customer_id}"

    artisan = Artisan.find_by(stripe_customer_id: stripe_customer_id)
    unless artisan
      Rails.logger.warn "Artisan not found for stripe_customer_id #{stripe_customer_id}"
      return
    end

    artisan.update(verified: false)

    Rails.logger.info "Artisan #{artisan.email} has been deactivated due to failed payment"
  end
end





