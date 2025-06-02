class CreateExpertises < ActiveRecord::Migration[7.1]
  def change
    create_table :expertises do |t|
      t.string :name

      t.timestamps
    end
    add_index :expertises, :name, unique: true
  end
end
