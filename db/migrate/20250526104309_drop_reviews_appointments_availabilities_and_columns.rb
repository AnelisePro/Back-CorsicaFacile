class DropReviewsAppointmentsAvailabilitiesAndColumns < ActiveRecord::Migration[7.1]
  def change
    # Supprimer les tables
    drop_table :reviews, if_exists: true
    drop_table :appointments, if_exists: true
    drop_table :availabilities, if_exists: true

    # Supprimer les colonnes de la table artisans
    remove_column :artisans, :description, :text if column_exists?(:artisans, :description)
    remove_column :artisans, :availability, :text if column_exists?(:artisans, :availability)
  end
end