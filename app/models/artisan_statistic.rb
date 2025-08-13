class ArtisanStatistic < ApplicationRecord
  belongs_to :artisan
  
  validates :date, presence: true, uniqueness: { scope: :artisan_id }
  validates :profile_views, :contact_clicks, :unique_visitors, numericality: { greater_than_or_equal_to: 0 }
  
  # Scopes pour les périodes
  scope :current_week, -> { where(date: 1.week.ago.beginning_of_day..Time.current.end_of_day) }
  scope :current_month, -> { where(date: 1.month.ago.beginning_of_day..Time.current.end_of_day) }
  scope :current_year, -> { where(date: 1.year.ago.beginning_of_day..Time.current.end_of_day) }
  
  # Méthodes calculées
  def conversion_rate
    return 0.0 if profile_views.zero?
    (contact_clicks.to_f / profile_views * 100).round(2)
  end
  
  def return_visitor_rate
    return 0.0 if unique_visitors.zero?
    (return_visitors.to_f / unique_visitors * 100).round(2)
  end
  
  def avg_time_to_contact_seconds
    return 0 if contact_count_for_timing.zero?
    total_time_to_contact / contact_count_for_timing
  end
  
  def avg_time_to_contact_formatted
    seconds = avg_time_to_contact_seconds
    return "0s" if seconds.zero?
    
    if seconds < 60
      "#{seconds}s"
    elsif seconds < 3600
      "#{(seconds / 60).round}m"
    else
      "#{(seconds / 3600).round(1)}h"
    end
  end
end
