# frozen_string_literal: true

class DeviseCreateAdmins < ActiveRecord::Migration[7.1]
    def change
    create_table :admins do |t|
      t.string :email,              null: false, default: ""
      t.string :encrypted_password, null: false, default: ""
      t.string :first_name
      t.string :last_name
      t.string :role, default: 'admin'
      t.boolean :active, default: true

      t.timestamps null: false
    end

    add_index :admins, :email, unique: true
  end
end
