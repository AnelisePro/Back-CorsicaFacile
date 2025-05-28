class AddDescriptionToArtisans < ActiveRecord::Migration[7.1]
  def change
    add_column :artisans, :description, :text
  end
end
