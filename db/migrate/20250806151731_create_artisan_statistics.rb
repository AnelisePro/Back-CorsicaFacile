class CreateArtisanStatistics < ActiveRecord::Migration[7.1]
  def change
    create_table :artisan_statistics do |t|
      t.references :artisan, null: false, foreign_key: true
      t.date :date
      
      # Statistiques de base (Pro + Premium)
      t.integer :profile_views, default: 0
      t.integer :contact_clicks, default: 0
      
      # Statistiques avancées (Premium seulement)
      t.json :views_by_hour, default: {} # {0: 5, 1: 2, ...}
      t.json :visitor_locations, default: {} # {"Ajaccio": 10, "Bastia": 5}
      t.json :device_types, default: {} # {"mobile": 15, "desktop": 8}
      t.float :avg_session_duration, default: 0.0
      t.integer :return_visitors, default: 0
      
      t.timestamps
    end
    
    add_index :artisan_statistics, [:artisan_id, :date], unique: true
  end
end
