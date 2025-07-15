class AddFileUrlsToArtisans < ActiveRecord::Migration[7.1]
  def change
    add_column :artisans, :kbis_url, :string
    add_column :artisans, :insurance_url, :string
  end
end
