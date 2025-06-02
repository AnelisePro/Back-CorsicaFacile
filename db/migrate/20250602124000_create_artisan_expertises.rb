class CreateArtisanExpertises < ActiveRecord::Migration[7.1]
  def change
    create_table :artisan_expertises do |t|
      t.references :artisan, null: false, foreign_key: true
      t.references :expertise, null: false, foreign_key: true

      t.timestamps
    end
  end
end
