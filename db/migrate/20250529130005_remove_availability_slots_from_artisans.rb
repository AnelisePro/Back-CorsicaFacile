class RemoveAvailabilitySlotsFromArtisans < ActiveRecord::Migration[7.1]
  def change
    # On vérifie si la colonne existe avant de la supprimer
    if column_exists?(:artisans, :availability_slots)
      remove_column :artisans, :availability_slots, :jsonb
    end
  end
end