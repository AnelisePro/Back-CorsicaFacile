class DropReviews < ActiveRecord::Migration[7.1]
  def up
    drop_table :reviews
  end

  def down
    create_table :reviews do |t|
      t.integer :rating, null: false
      t.text :comment, null: false
      t.integer :helpful_count, default: 0
      
      # Relations polymorphiques pour Client OU Artisan
      t.references :reviewable, polymorphic: true, null: false, index: true
      
      t.boolean :is_approved, default: false
      t.boolean :is_featured, default: false

      t.timestamps
    end

    add_index :reviews, :rating
    add_index :reviews, :is_approved
    add_index :reviews, :created_at
    add_index :reviews, [:reviewable_type, :reviewable_id, :created_at], name: 'index_reviews_on_reviewable_and_date'
  end
end

