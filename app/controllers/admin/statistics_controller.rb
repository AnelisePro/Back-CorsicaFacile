class Admin::StatisticsController < Admin::BaseController
  def index
    period = params[:period] || 'week' # day, week, month
    
    case period
    when 'day'
      stats = SiteStatistic.recent(1)
    when 'week'
      stats = SiteStatistic.recent(7)
    when 'month'
      stats = SiteStatistic.recent(30)
    end
    
    render json: {
      statistics: stats.order(:date),
      summary: calculate_summary(stats)
    }
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