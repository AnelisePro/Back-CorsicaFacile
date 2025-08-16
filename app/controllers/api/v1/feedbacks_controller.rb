class Api::V1::FeedbacksController < ApplicationController
  before_action :authenticate_user!, except: [:index]
  
  def index
    # Affiche seulement les feedbacks publics avec réponse admin
    @feedbacks = Feedback.where(status: 'responded')
                        .where.not(admin_response: [nil, ''])
                        .order(created_at: :desc)
                        .limit(10)
    
    render json: @feedbacks.map { |feedback| public_feedback_json(feedback) }
  end
  
  def create
    @feedback = build_feedback_for_current_user
    
    if @feedback.save
      render json: { 
        success: true, 
        message: 'Votre avis a été envoyé avec succès ! Il sera visible après validation par notre équipe.' 
      }
    else
      render json: { 
        success: false, 
        errors: @feedback.errors.full_messages 
      }, status: 422
    end
  end
  
  private
  
  def authenticate_user!
    # Utilise l'authentification Devise
    unless client_signed_in? || artisan_signed_in?
      render json: { error: 'Vous devez être connecté pour effectuer cette action' }, status: 401
    end
  end
  
  def current_user
    # Retourne le client ou l'artisan connecté via Devise
    current_client || current_artisan
  end
  
  def build_feedback_for_current_user
    feedback = current_user.feedbacks.build(feedback_params)
    
    if current_client
      feedback.user_type = 'Client'
    elsif current_artisan
      feedback.user_type = 'Artisan'
    end
    
    feedback.status = 'pending'
    feedback
  end
  
  def feedback_params
    params.require(:feedback).permit(:title, :content)
  end
  
  def public_feedback_json(feedback)
    # Déterminer le nom d'affichage selon le type d'utilisateur
    user_name = case feedback.user_type
    when 'Client'
      if feedback.user.respond_to?(:first_name) && feedback.user.respond_to?(:last_name)
        "#{feedback.user.first_name} #{feedback.user.last_name}".strip
      else
        "Client"
      end
    when 'Artisan'
      feedback.user&.company_name || "Artisan"
    else
      "Utilisateur"
    end
    
    {
      id: feedback.id,
      title: feedback.title,
      content: feedback.content,
      user_name: user_name,
      user_type: feedback.user_type,
      admin_response: feedback.admin_response,
      created_at: feedback.created_at.strftime("%d/%m/%Y à %H:%M"),
      responded_at: feedback.responded_at&.strftime("%d/%m/%Y à %H:%M")
    }
  end
end

