class CreateNotifications < ActiveRecord::Migration[7.1]
  def change
    create_table :notifications do |t|
      t.references :artisan, null: false, foreign_key: true
      t.string :message
      t.string :link
      t.boolean :read

      t.timestamps
    end
  end
end
