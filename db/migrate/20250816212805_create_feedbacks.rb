class CreateFeedbacks < ActiveRecord::Migration[7.1]
  def change
    create_table :feedbacks do |t|
      t.references :user, polymorphic: true, null: false
      t.string :title, null: false
      t.text :content, null: false
      t.string :status, default: 'pending'
      t.text :admin_response
      t.datetime :responded_at

      t.timestamps
    end

    add_index :feedbacks, [:user_type, :user_id]
    add_index :feedbacks, :status
    add_index :feedbacks, :created_at
  end
end
