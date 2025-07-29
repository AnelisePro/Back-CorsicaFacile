class Admin::DashboardController < Admin::BaseController
  def index
    render json: {
      total_clients: Client.count,
      total_artisans: Artisan.count,
      total_announcements: Announcement.count,
      total_messages: Message.count,
      recent_signups: recent_signups_data,
      daily_stats: daily_statistics
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
end