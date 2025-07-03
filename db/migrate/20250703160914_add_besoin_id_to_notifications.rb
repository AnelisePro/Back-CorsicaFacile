class AddBesoinIdToNotifications < ActiveRecord::Migration[7.1]
  def change
    add_reference :notifications, :besoin, null: true, foreign_key: true
  end
end
