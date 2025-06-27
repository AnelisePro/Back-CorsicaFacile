class AddImageUrlsToBesoins < ActiveRecord::Migration[7.1]
  def change
    add_column :besoins, :image_urls, :jsonb, default: []
  end
end
