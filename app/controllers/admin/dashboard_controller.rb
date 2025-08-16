class Admin::DashboardController < Admin::BaseController
  def index
    render json: {
      total_clients: Client.count,
      total_artisans: Artisan.count,
      total_besoins: Besoin.count,
      total_conversations: Conversation.count,
      total_feedbacks: Feedback.count,
      pending_feedbacks: Feedback.pending.count,
      recent_signups: recent_signups_data,
      daily_stats: daily_statistics,
      recent_feedbacks: recent_feedbacks_data,
      feedback_stats: feedback_statistics,
      growth_stats: growth_statistics
    }
  end
  
  private
  
  def recent_signups_data
    {
      clients_today: Client.where(created_at: Date.current.beginning_of_day..Date.current.end_of_day).count,
      artisans_today: Artisan.where(created_at: Date.current.beginning_of_day..Date.current.end_of_day).count,
      clients_this_week: Client.where(created_at: 1.week.ago..Date.current).count,
      artisans_this_week: Artisan.where(created_at: 1.week.ago..Date.current).count
    }
  end
  
  def daily_statistics
    SiteStatistic.recent(7).order(:date)
  end

  def recent_feedbacks_data
    Feedback.recent.includes(:user).limit(5).map do |feedback|
      {
        id: feedback.id,
        title: feedback.title,
        user_name: get_user_name(feedback.user, feedback.user_type),
        user_type: feedback.user_type,
        status: feedback.status,
        created_at: feedback.created_at.strftime("%d/%m/%Y"),
        urgency: feedback.status == 'pending' ? 'high' : 'normal'
      }
    end
  end

  def get_user_name(user, user_type)
    return "Utilisateur supprimé" if user.nil?
    
    case user_type
    when 'Client'
      if user.respond_to?(:first_name) && user.respond_to?(:last_name)
        "#{user.first_name} #{user.last_name}".strip
      elsif user.respond_to?(:name)
        user.name
      else
        "Client"
      end
    when 'Artisan'
      if user.respond_to?(:company_name)
        user.company_name
      else
        "Artisan"
      end
    else
      "Utilisateur"
    end
  end

  def feedback_statistics
    {
      total: Feedback.count,
      pending: Feedback.pending.count,
      responded: Feedback.responded.count,
      archived: Feedback.archived.count,
      this_week: Feedback.where('created_at >= ?', 1.week.ago).count,
      this_month: Feedback.where('created_at >= ?', 1.month.ago).count,
      by_user_type: {
        clients: Feedback.where(user_type: 'Client').count,
        artisans: Feedback.where(user_type: 'Artisan').count
      }
    }
  end

  def growth_statistics
    {
      users_growth: calculate_growth(:users),
      besoins_growth: calculate_growth(:besoins),
      conversations_growth: calculate_growth(:conversations),
      feedbacks_growth: calculate_growth(:feedbacks)
    }
  end

  def calculate_growth(type)
    current_month = Date.current.beginning_of_month
    previous_month = 1.month.ago.beginning_of_month

    case type
    when :users
      current = (Client.where('created_at >= ?', current_month).count + 
                Artisan.where('created_at >= ?', current_month).count)
      previous = (Client.where('created_at >= ? AND created_at < ?', previous_month, current_month).count + 
                 Artisan.where('created_at >= ? AND created_at < ?', previous_month, current_month).count)
    when :besoins
      current = Besoin.where('created_at >= ?', current_month).count
      previous = Besoin.where('created_at >= ? AND created_at < ?', previous_month, current_month).count
    when :conversations
      current = Conversation.where('created_at >= ?', current_month).count
      previous = Conversation.where('created_at >= ? AND created_at < ?', previous_month, current_month).count
    when :feedbacks
      current = Feedback.where('created_at >= ?', current_month).count
      previous = Feedback.where('created_at >= ? AND created_at < ?', previous_month, current_month).count
    else
      return 0
    end
    
    return 0 if previous.zero?
    ((current - previous).to_f / previous * 100).round(1)
  rescue
    0
  end
end

