class RemoveExpertiseFromArtisans < ActiveRecord::Migration[7.1]
  def change
    remove_column :artisans, :expertise, :string
  end
end
