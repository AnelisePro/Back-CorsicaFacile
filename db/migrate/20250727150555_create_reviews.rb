class CreateReviews < ActiveRecord::Migration[7.1]
  def change
    create_table :reviews do |t|
      t.references :client, null: false, foreign_key: true
      t.references :artisan, null: false, foreign_key: true
      t.references :client_notification, null: false, foreign_key: true
      t.integer :rating, null: false
      t.text :comment, null: false
      t.boolean :intervention_successful

      t.timestamps
    end

    add_index :reviews, [:client_id, :artisan_id, :client_notification_id], 
              unique: true, name: 'index_reviews_unique_per_mission'
  end
end
