class Admin::UsersController < Admin::BaseController
  def index
    users = []
    
    # Clients
    Client.includes(:announcements).find_each do |client|
      users << format_user_data(client, 'client')
    end
    
    # Artisans
    Artisan.includes(:responses).find_each do |artisan|
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
    user.update!(banned: true, banned_at: Time.current, banned_by: current_admin.id)
    
    render json: { message: 'Utilisateur banni avec succès' }
  end
  
  def unban
    user_type = params[:user_type]
    user_id = params[:id]
    
    user = user_type == 'client' ? Client.find(user_id) : Artisan.find(user_id)
    user.update!(banned: false, banned_at: nil, banned_by: nil)
    
    render json: { message: 'Utilisateur débanni avec succès' }
  end
  
  private
  
  def format_user_data(user, type)
    base_data = {
      id: user.id,
      type: type,
      email: user.email,
      created_at: user.created_at,
      banned: user.banned || false,
      last_login: user.current_sign_in_at,
      activity_count: type == 'client' ? user.announcements.count : user.responses.count
    }
    
    # Ajout des champs spécifiques selon le type
    if type == 'client'
      base_data.merge!({
        first_name: user.first_name,
        last_name: user.last_name,
        full_name: "#{user.first_name} #{user.last_name}".strip
      })
    else # artisan
      base_data.merge!({
        company_name: user.company_name,
        full_name: user.company_name
      })
    end
    
    base_data
  end
  
  def format_detailed_user_data(user, type)
    base_data = format_user_data(user, type)
    
    if type == 'client'
      base_data[:announcements] = user.announcements.limit(10).map do |announcement|
        {
          id: announcement.id,
          title: announcement.title,
          created_at: announcement.created_at,
          responses_count: announcement.responses.count
        }
      end
    else # artisan
      base_data[:responses] = user.responses.limit(10).includes(:announcement).map do |response|
        {
          id: response.id,
          announcement_title: response.announcement.title,
          created_at: response.created_at
        }
      end
      base_data[:specialties] = user.specialties if user.respond_to?(:specialties)
    end
    
    base_data
  end
end
