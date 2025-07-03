class Notification < ApplicationRecord
  belongs_to :artisan
  belongs_to :besoin, optional: true
end
