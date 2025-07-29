class Admin::StatisticsController < Admin::BaseController
  def index
    period = params[:groupBy] || params[:period] || 'week'
    
    case period
    when 'day'
      stats = SiteStatistic.recent(1)
    when 'week'
      stats = SiteStatistic.recent(7)
    when 'month'
      stats = SiteStatistic.recent(30)
    end
    
    # Formater les données selon l'interface TypeScript
    formatted_stats = stats.order(:date).map do |stat|
      {
        date: stat.date.to_s,
        pageViews: stat.page_views || 0,
        uniqueVisitors: stat.unique_visitors || 0,
        clientSignups: stat.client_signups || 0,
        artisanSignups: stat.artisan_signups || 0,
        messagesSent: stat.messages_sent || 0,
        announcementsPosted: stat.announcements_posted || 0
      }
    end
    
    # Retourner directement le tableau formaté
    render json: formatted_stats
  end
  
  private
  
  def calculate_summary(stats)
    {
      total_page_views: stats.sum(:page_views),
      total_unique_visitors: stats.sum(:unique_visitors),
      total_signups: stats.sum(:client_signups) + stats.sum(:artisan_signups),
      average_daily_visitors: stats.average(:unique_visitors).to_f.round(2)
    }
  end
end
