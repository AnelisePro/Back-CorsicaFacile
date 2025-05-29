class RemoveAvailabilitySlotsFromArtisans < ActiveRecord::Migration[7.1]
  def change
    remove_column :artisans, :availability_slots, :jsonb
  end
end