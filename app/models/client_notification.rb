class ClientNotification < ApplicationRecord
  belongs_to :client
  belongs_to :artisan
  belongs_to :besoin

  validates :message, presence: true
  validates :status, inclusion: { in: ['pending', 'accepted', 'refused', 'in_progress', 'completed'] }
  validates :client_id, presence: true
  validates :besoin_id, presence: true
  validates :artisan_id, presence: true
end
