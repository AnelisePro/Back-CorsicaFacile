class AvailabilitySlot < ApplicationRecord
  belongs_to :artisan

  validates :start_time, :end_time, presence: true
  validate :end_after_start

  private

  def end_after_start
    errors.add(:end_time, "doit être après le début") if end_time <= start_time
  end
end