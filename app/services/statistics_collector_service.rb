class StatisticsCollectorService
  def self.collect_daily_stats(date = Date.current)
    stat = SiteStatistic.find_or_create_by(date: date)
    
    stat.update!(
      client_signups: Client.where(created_at: date.beginning_of_day..date.end_of_day).count,
      artisan_signups: Artisan.where(created_at: date.beginning_of_day..date.end_of_day).count,
      messages_sent: Conversation.where(created_at: date.beginning_of_day..date.end_of_day).count,
      announcements_posted: Besoin.where(created_at: date.beginning_of_day..date.end_of_day).count
    )
  end
  
  def self.increment_page_view(date = Date.current)
    stat = SiteStatistic.find_or_create_by(date: date)
    stat.increment!(:page_views)
  end
  
  def self.increment_unique_visitor(date = Date.current)
    stat = SiteStatistic.find_or_create_by(date: date)
    stat.increment!(:unique_visitors)
  end
end