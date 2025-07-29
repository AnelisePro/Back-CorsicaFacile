class AddBannedFieldsToArtisans < ActiveRecord::Migration[7.1]
  def change
    add_column :artisans, :banned_at, :datetime
    add_column :artisans, :banned_by, :integer
  end
end
