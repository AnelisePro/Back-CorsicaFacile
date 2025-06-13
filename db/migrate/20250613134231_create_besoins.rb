class CreateBesoins < ActiveRecord::Migration[7.1]
  def change
    create_table :besoins do |t|
      t.string :type_prestation
      t.text :description
      t.datetime :schedule
      t.string :address
      t.references :client, null: false, foreign_key: true

      t.timestamps
    end
  end
end
