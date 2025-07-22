class CreateConversations < ActiveRecord::Migration[7.1]
  def change
    create_table :conversations do |t|
      t.references :client, null: false, foreign_key: true
      t.references :artisan, null: false, foreign_key: true
      t.timestamps
    end
    
    add_index :conversations, [:client_id, :artisan_id], unique: true
  end
end

