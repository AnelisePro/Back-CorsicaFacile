class AnnouncementResponsesController < ApplicationController
  before_action :authenticate_artisan!

  def create
    current_artisan.reset_monthly_counter_if_needed

    unless current_artisan.can_respond_to_announcement?
      return render json: {
        error: error_message_for_limit,
        upgrade_suggestion: get_upgrade_suggestion,
        next_reset_date: current_artisan.next_reset_date
      }, status: :unprocessable_entity
    end

    # Incrémenter le compteur
    if current_artisan.increment_response_count!
      # Créer la notification pour le client
      create_client_notification

      # Recharger l'artisan pour avoir les nouvelles stats
      current_artisan.reload

      render json: {
        message: 'Réponse envoyée avec succès',
        usage_stats: usage_stats_hash
      }, status: :created
    else
      render json: {
        error: 'Impossible d\'envoyer la réponse - limite atteinte'
      }, status: :unprocessable_entity
    end
  end

  def usage_stats
    current_artisan.reset_monthly_counter_if_needed

    render json: usage_stats_hash
  end

  private

  def usage_stats_hash
    {
      membership_plan: current_artisan.membership_plan,
      response_limit: current_artisan.response_limit,
      responses_used: current_artisan.monthly_response_count,
      remaining_responses: current_artisan.remaining_responses,
      usage_percentage: current_artisan.responses_used_percentage,
      next_reset_date: current_artisan.next_reset_date,
      can_respond: current_artisan.can_respond_to_announcement?
    }
  end

  def error_message_for_limit
    if current_artisan.response_limit.zero? && current_artisan.membership_plan != 'Premium'
      "Votre formule est invalide ou non reconnue. Veuillez contacter le support ou mettre à jour votre abonnement."
    else
      "Limite de réponses mensuelle atteinte. Votre formule #{current_artisan.membership_plan || '(non définie)'} permet #{current_artisan.response_limit} réponses par mois."
    end
  end

  def create_client_notification
    besoin_id = response_params[:besoin_id]
    client_id = response_params[:client_id]

    Notification.create!(
      recipient_type: 'Client',
      recipient_id: client_id,
      artisan: current_artisan,
      message: "#{current_artisan.company_name} est intéressé par votre demande",
      notification_type: 'interest',
      data: {
        besoin_id: besoin_id,
        artisan_id: current_artisan.id
      }
    )
  rescue => e
    Rails.logger.error "Erreur lors de la création de la notification: #{e.message}"
  end

  def response_params
    params.require(:announcement_response).permit(:besoin_id, :client_id, :message)
  end

  def get_upgrade_suggestion
    case current_artisan.membership_plan
    when 'Standard'
      'Passez à la formule Pro pour 6 réponses par mois, ou Premium pour un accès illimité.'
    when 'Pro'
      'Passez à la formule Premium pour un accès illimité aux réponses.'
    when 'Premium'
      nil
    else
      'Votre abonnement semble invalide. Veuillez contacter le support ou choisir un abonnement valide.'
    end
  end
end


