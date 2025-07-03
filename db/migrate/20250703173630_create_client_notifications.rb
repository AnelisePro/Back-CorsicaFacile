class CreateClientNotifications < ActiveRecord::Migration[7.1]
  def change
    create_table :client_notifications do |t|
      t.references :client, null: false, foreign_key: true
      t.references :artisan, null: false, foreign_key: true
      t.references :besoin, null: false, foreign_key: true
      t.string :message, null: false
      t.string :link
      t.string :status, null: false, default: 'pending' # pending / accepted / refused

      t.timestamps
    end
  end
end
