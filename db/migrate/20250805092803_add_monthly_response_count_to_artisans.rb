class AddMonthlyResponseCountToArtisans < ActiveRecord::Migration[7.1]
  def change
    add_column :artisans, :monthly_response_count, :integer, default: 0
    add_column :artisans, :last_response_reset_at, :datetime
    
    # Initialize existing artisans
    reversible do |dir|
      dir.up do
        Artisan.update_all(
          monthly_response_count: 0,
          last_response_reset_at: Time.current.beginning_of_month
        )
      end
    end
  end
end
