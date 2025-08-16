class Admin::FeedbacksController < Admin::BaseController 
  before_action :set_feedback, only: [:show, :update, :destroy]
  
  def index
    @feedbacks = Feedback.recent.includes(:user)
    
    # Filtrage par statut
    @feedbacks = @feedbacks.where(status: params[:status]) if params[:status].present?
    
    # Filtrage par type d'utilisateur
    @feedbacks = @feedbacks.where(user_type: params[:user_type]) if params[:user_type].present?
    
    # Recherche
    if params[:search].present?
      @feedbacks = @feedbacks.where(
        "title ILIKE ? OR content ILIKE ?", 
        "%#{params[:search]}%", 
        "%#{params[:search]}%"
      )
    end
    
    # Pagination
    page = params[:page]&.to_i || 1
    per_page = params[:per_page]&.to_i || 20
    offset = (page - 1) * per_page
    
    total_count = @feedbacks.count
    @feedbacks = @feedbacks.limit(per_page).offset(offset)
    
    render json: {
      feedbacks: @feedbacks.map { |feedback| admin_feedback_json(feedback) },
      pagination: {
        current_page: page,
        per_page: per_page,
        total_pages: (total_count.to_f / per_page).ceil,
        total_count: total_count
      },
      stats: {
        total: Feedback.count,
        pending: Feedback.pending.count,
        responded: Feedback.responded.count,
        archived: Feedback.archived.count
      }
    }
  end
  
  def show
    render json: { feedback: admin_feedback_json(@feedback) }
  end
  
  def update
    if @feedback.update(admin_feedback_params)
      # Mettre à jour automatiquement le statut si une réponse est ajoutée
      if @feedback.admin_response.present? && @feedback.status == 'pending'
        @feedback.update(responded_at: Time.current, status: 'responded')
      end
      
      render json: { 
        success: true, 
        message: 'Réponse ajoutée avec succès !',
        feedback: admin_feedback_json(@feedback)
      }
    else
      render json: { 
        success: false, 
        errors: @feedback.errors.full_messages 
      }, status: 422
    end
  end
  
  def destroy
    @feedback.update(status: 'archived')
    render json: { 
      success: true, 
      message: 'Feedback archivé avec succès' 
    }
  end
  
  # Action pour changer le statut en masse
  def bulk_update
    feedback_ids = params[:feedback_ids]
    action = params[:bulk_action]
    
    return render json: { error: 'Paramètres manquants' }, status: 400 if feedback_ids.blank? || action.blank?
    
    feedbacks = Feedback.where(id: feedback_ids)
    
    case action
    when 'archive'
      feedbacks.update_all(status: 'archived')
      message = "#{feedbacks.count} feedback(s) archivé(s)"
    when 'mark_responded'
      feedbacks.update_all(status: 'responded', responded_at: Time.current)
      message = "#{feedbacks.count} feedback(s) marqué(s) comme traité(s)"
    when 'mark_pending'
      feedbacks.update_all(status: 'pending', responded_at: nil)
      message = "#{feedbacks.count} feedback(s) marqué(s) en attente"
    else
      return render json: { error: 'Action non reconnue' }, status: 400
    end
    
    render json: { 
      success: true, 
      message: message 
    }
  end
  
  private
  
  def set_feedback
    @feedback = Feedback.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Feedback non trouvé' }, status: 404
  end
  
  def admin_feedback_params
    params.require(:feedback).permit(:admin_response, :status)
  end
  
  def admin_feedback_json(feedback)
    user_info = if feedback.user
      case feedback.user_type
      when 'Client'
        if feedback.user.respond_to?(:first_name) && feedback.user.respond_to?(:last_name)
          {
            name: "#{feedback.user.first_name} #{feedback.user.last_name}".strip,
            email: feedback.user.email,
            id: feedback.user.id
          }
        else
          {
            name: "Client",
            email: feedback.user.email,
            id: feedback.user.id
          }
        end
      when 'Artisan'
        {
          name: feedback.user.company_name || "Artisan",
          email: feedback.user.email,
          id: feedback.user.id
        }
      else
        {
          name: "Utilisateur",
          email: feedback.user.email || "Non disponible",
          id: feedback.user.id
        }
      end
    else
      {
        name: "Utilisateur supprimé",
        email: "Non disponible",
        id: nil
      }
    end

    {
 id: feedback.id,
  title: feedback.title,
  content: feedback.content,
  user: user_info,
  user_type: feedback.user_type,
  status: feedback.status,
  admin_response: feedback.admin_response,
  # Envoyez les dates en format ISO pour JavaScript
  created_at: feedback.created_at.iso8601,
  responded_at: feedback.responded_at&.iso8601,
  days_pending: feedback.status == 'pending' ? (Date.current - feedback.created_at.to_date).to_i : nil
    }
  end
end

