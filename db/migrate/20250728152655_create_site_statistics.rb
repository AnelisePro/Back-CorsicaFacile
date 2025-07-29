class CreateSiteStatistics < ActiveRecord::Migration[7.1]
  def change
    create_table :site_statistics do |t|
      t.date :date, null: false
      t.integer :page_views, default: 0
      t.integer :unique_visitors, default: 0
      t.integer :client_signups, default: 0
      t.integer :artisan_signups, default: 0
      t.integer :client_logins, default: 0
      t.integer :artisan_logins, default: 0
      t.integer :messages_sent, default: 0
      t.integer :announcements_posted, default: 0
      
      t.timestamps
    end
    
    add_index :site_statistics, :date, unique: true
  end
end
