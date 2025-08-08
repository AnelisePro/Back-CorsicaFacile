class ArtisanStatistic < ApplicationRecord
  belongs_to :artisan
  
  validates :date, presence: true, uniqueness: { scope: :artisan_id }
  
  scope :for_period, ->(start_date, end_date) { where(date: start_date..end_date) }
  scope :current_week, -> { where(date: 1.week.ago..Date.current) }
  scope :current_month, -> { where(date: 1.month.ago..Date.current) }
  
  def conversion_rate
    return 0.0 if profile_views.zero?
    (contact_clicks.to_f / profile_views * 100).round(2)
  end
end