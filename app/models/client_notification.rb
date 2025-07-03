class ClientNotification < ApplicationRecord
  belongs_to :client
  belongs_to :artisan
  belongs_to :besoin

  validates :message, presence: true
  validates :status, inclusion: { in: ['pending', 'accepted', 'refused'] }
end
