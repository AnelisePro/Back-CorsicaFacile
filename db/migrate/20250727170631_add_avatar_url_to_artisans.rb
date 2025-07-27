class AddAvatarUrlToArtisans < ActiveRecord::Migration[7.1]
  def change
    add_column :artisans, :avatar_url, :string
  end
end
