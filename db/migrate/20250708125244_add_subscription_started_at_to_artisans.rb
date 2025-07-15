class AddSubscriptionStartedAtToArtisans < ActiveRecord::Migration[7.1]
  def change
    add_column :artisans, :subscription_started_at, :datetime
  end
end
