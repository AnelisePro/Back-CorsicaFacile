class ReviewsController < ApplicationController
  def create
    puts "🚀 [DEBUG] create appelé"
    puts "🚀 [DEBUG] params: #{params.inspect}"
    puts "🚀 [DEBUG] review_params: #{review_params.inspect}"
    puts "🚀 [DEBUG] current_client: #{current_client&.id}"

    begin
      @review = Review.new(review_params)
      @review.client = current_client
      
      puts "🚀 [DEBUG] Review créée: #{@review.inspect}"
      puts "🚀 [DEBUG] Review valid?: #{@review.valid?}"
      puts "🚀 [DEBUG] Errors: #{@review.errors.full_messages}" unless @review.valid?

      if @review.save
        puts "✅ [DEBUG] Review sauvegardée avec succès"
        
        # Marquer la notification comme reviewed
        notification = ClientNotification.find(review_params[:client_notification_id])
        notification.update(status: 'reviewed')
        
        render json: {
          message: 'Avis créé avec succès',
          review: @review
        }, status: :created
      else
        puts "❌ [DEBUG] Echec sauvegarde: #{@review.errors.full_messages}"
        render json: {
          error: 'Impossible de créer l\'avis',
          errors: @review.errors.full_messages
        }, status: :unprocessable_entity
      end
    rescue => e
      puts "❌ [DEBUG] Exception: #{e.message}"
      puts "❌ [DEBUG] Backtrace: #{e.backtrace.first(10)}"
      render json: { error: e.message }, status: :internal_server_error
    end
  end

  def show
    @client_notification = ClientNotification.find(params[:notification_id])
    @artisan = @client_notification.artisan
    
    # Vérifier que le client est propriétaire de la notification
    unless @client_notification.client == current_client
      render json: { error: 'Non autorisé' }, status: :unauthorized
      return
    end

    # Vérifier si un avis existe déjà
    existing_review = Review.find_by(
      client: current_client, 
      artisan: @artisan, 
      client_notification: @client_notification
    )

    render json: {
      artisan: @artisan.as_json(only: [:id, :company_name]),
      notification: @client_notification.as_json(only: [:id, :status]),
      existing_review: existing_review,
      can_review: existing_review.nil? && @client_notification.status == 'completed'
    }
  end

  def for_notification
    notification = ClientNotification.find(params[:notification_id])
    
    # Vérifier que la notification appartient au client connecté
    unless notification.client_id == current_client.id
      render json: { error: 'Non autorisé' }, status: :forbidden
      return
    end

    # Vérifier que la mission est terminée
    unless notification.status == 'completed'
      render json: { 
        error: 'La mission doit être terminée pour laisser un avis',
        can_review: false 
      }, status: :unprocessable_entity
      return
    end

    # Vérifier qu'il n'y a pas déjà un avis
    existing_review = Review.find_by(
      client_notification_id: notification.id,
      client_id: current_client.id
    )

    if existing_review
      render json: { 
        error: 'Vous avez déjà laissé un avis pour cette mission',
        can_review: false,
        existing_review: existing_review
      }, status: :unprocessable_entity
      return
    end

    # Récupérer les données de l'artisan
    artisan = notification.artisan

    render json: {
      artisan: {
        id: artisan.id,
        company_name: artisan.company_name,
      },
      notification: {
        id: notification.id,
        status: notification.status
      },
      can_review: true,
      existing_review: nil
    }
  rescue ActiveRecord::RecordNotFound
    render json: { 
      error: 'Notification non trouvée', 
      can_review: false 
    }, status: :not_found
  end

  # Méthode pour récupérer les avis d'un artisan (pour la page profil)
  def index
    artisan = Artisan.find(params[:artisan_id])
    reviews = artisan.reviews.includes(:client).order(created_at: :desc)
    
    puts "🔍 [DEBUG] Artisan: #{artisan.company_name}"
    puts "🔍 [DEBUG] Reviews found: #{reviews.count}"
    
    # Calcul des statistiques
    total_reviews = reviews.count
    average_rating = total_reviews > 0 ? reviews.average(:rating).to_f.round(1) : 0.0
    
    # Distribution des notes
    rating_distribution = [1, 2, 3, 4, 5].map do |rating|
      reviews.where(rating: rating).count
    end

    stats = {
      total_reviews: total_reviews,
      average_rating: average_rating,
      rating_distribution: rating_distribution
    }

    puts "🔍 [DEBUG] Stats: #{stats}"

    render json: {
      reviews: reviews.as_json(include: {
        client: { only: [:first_name, :last_name, :avatar_url] }
      }),
      stats: stats
    }
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Artisan non trouvé' }, status: :not_found
  end

  private

  def review_params
    params.require(:review).permit(:rating, :comment, :intervention_successful, :artisan_id, :client_notification_id)
  end
end



