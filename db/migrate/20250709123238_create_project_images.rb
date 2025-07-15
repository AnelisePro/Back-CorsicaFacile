class CreateProjectImages < ActiveRecord::Migration[7.1]
  def change
    create_table :project_images do |t|
      t.references :artisan, null: false, foreign_key: true

      t.timestamps
    end
  end
end
