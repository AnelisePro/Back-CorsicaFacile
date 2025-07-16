class CreateMessages < ActiveRecord::Migration[7.1]
    def change
    create_table :messages do |t|
      t.text :content, null: false
      t.references :conversation, null: false, foreign_key: true
      t.references :sender, polymorphic: true, null: false
      t.references :recipient, polymorphic: true, null: false
      t.boolean :read, default: false
      t.timestamps
    end
    
    add_index :messages, [:conversation_id, :created_at]
    add_index :messages, [:sender_type, :sender_id]
    add_index :messages, [:recipient_type, :recipient_id]
  end
end
