class SiteStatistic < ApplicationRecord
  validates :date, presence: true, uniqueness: true
  validates :page_views, :unique_visitors, :client_signups, 
            :artisan_signups, :client_logins, :artisan_logins, :messages_sent, :announcements_posted,
            presence: true, numericality: { greater_than_or_equal_to: 0 }

  scope :by_date_range, ->(start_date, end_date) { where(date: start_date..end_date) }
  scope :recent, ->(days = 30) { where(date: days.days.ago..Date.current) }
end