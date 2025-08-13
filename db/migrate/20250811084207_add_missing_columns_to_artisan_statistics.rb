class AddMissingColumnsToArtisanStatistics < ActiveRecord::Migration[7.1]
  def change
    # Pour calculer le temps moyen avant contact
    add_column :artisan_statistics, :total_time_to_contact, :integer, default: 0
    add_column :artisan_statistics, :contact_count_for_timing, :integer, default: 0
    
    # Pour les vues uniques (éviter de compter plusieurs fois le même visiteur)
    add_column :artisan_statistics, :unique_visitors, :integer, default: 0
    
    # Index pour optimiser les requêtes par période
    add_index :artisan_statistics, :date
    add_index :artisan_statistics, [:artisan_id, :date], name: 'index_artisan_stats_on_artisan_and_date'
  end
end
