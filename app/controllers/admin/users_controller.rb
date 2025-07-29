class Admin::UsersController < Admin::BaseController
  def index
    users = []
    
    # Clients
    Client.includes(:besoins).find_each do |client|
      users << format_user_data(client, 'client')
    end
    
    # Artisans avec leurs conversations pour optimiser les requêtes
    Artisan.includes(:conversations, :sent_messages).find_each do |artisan|
      users << format_user_data(artisan, 'artisan')
    end
    
    # Tri par date de création (plus récent en premier)
    users.sort_by! { |user| user[:created_at] }.reverse!
    
    render json: { users: users }
  end
  
  def show
    user_type = params[:user_type]
    user_id = params[:id]
    user = user_type == 'client' ? Client.find(user_id) : Artisan.find(user_id)
    
    render json: {
      user: format_detailed_user_data(user, user_type)
    }
  end
  
  def ban
    user_type = params[:user_type]
    user_id = params[:id]
    user = user_type == 'client' ? Client.find(user_id) : Artisan.find(user_id)
    
    user.ban!(current_admin.id)
    render json: { message: 'Utilisateur banni avec succès' }
  end
  
  def unban
    user_type = params[:user_type]
    user_id = params[:id]
    user = user_type == 'client' ? Client.find(user_id) : Artisan.find(user_id)
    
    user.unban!
    render json: { message: 'Utilisateur débanni avec succès' }
  end
  
  private
  
  def format_user_data(user, type)
    base_data = {
      id: user.id,
      type: type,
      email: user.email,
      created_at: user.created_at,
      banned: user.respond_to?(:banned?) ? user.banned? : false,
      last_login: user.updated_at,
      # ✅ CORRECTION: Utiliser les messages comme activité
      activity_count: calculate_activity_count(user, type),
      phone: user.phone,
      city: user.respond_to?(:city) ? user.city : (user.respond_to?(:address) ? user.address : nil)
    }
    
    if type == 'client'
      base_data.merge!({
        first_name: user.first_name,
        last_name: user.last_name,
        full_name: "#{user.first_name} #{user.last_name}".strip
      })
    else # artisan
      base_data.merge!({
        company_name: user.company_name,
        full_name: user.company_name,
        verified: user.respond_to?(:verified?) ? user.verified? : false,
        average_rating: user.average_rating,
        total_reviews: user.total_reviews
      })
    end
    
    base_data
  end
  
  def format_detailed_user_data(user, type)
    base_data = format_user_data(user, type)
    
    if type == 'client'
      base_data[:besoins] = user.besoins.limit(10).map do |besoin|
        {
          id: besoin.id,
          title: besoin.title,
          created_at: besoin.created_at,
          # ✅ Compter les conversations liées à ce besoin si l'association existe
          responses_count: besoin.respond_to?(:conversations) ? besoin.conversations.count : 0
        }
      end
      
      # ✅ Ajouter les messages envoyés par le client
      base_data[:recent_messages] = user.sent_messages.limit(5).includes(:conversation).map do |message|
        {
          id: message.id,
          content: message.content.truncate(100),
          created_at: message.created_at,
          conversation_id: message.conversation_id
        }
      end
      
    else # artisan
      base_data.merge!({
        expertises: user.expertises.map { |e| { id: e.id, name: e.respond_to?(:name) ? e.name : e.to_s } },
        
        # ✅ Messages récents de l'artisan
        recent_messages: user.sent_messages.limit(10).includes(:conversation).map do |message|
          {
            id: message.id,
            content: message.content.truncate(100),
            created_at: message.created_at,
            conversation_id: message.conversation_id
          }
        end,
        
        # ✅ Conversations actives
        active_conversations: user.conversations.limit(5).map do |conversation|
          {
            id: conversation.id,
            created_at: conversation.created_at,
            updated_at: conversation.updated_at,
            messages_count: conversation.respond_to?(:messages) ? conversation.messages.count : 0
          }
        end,
        
        reviews: user.reviews.limit(5).map do |review|
          {
            id: review.id,
            rating: review.rating,
            comment: review.respond_to?(:comment) ? review.comment : '',
            created_at: review.created_at
          }
        end,
        
        address: user.address,
        siren: user.siren,
        verified: user.respond_to?(:verified?) ? user.verified? : false
      })
    end
    
    base_data
  end
  
  def calculate_activity_count(user, type)
    if type == 'client'
      # ✅ Pour les clients : nombre de besoins + messages envoyés
      user.besoins.count + user.sent_messages.count
    else # artisan
      # ✅ Pour les artisans : messages envoyés + conversations + reviews
      user.sent_messages.count + user.conversations.count + user.reviews.count
    end
  end
end

