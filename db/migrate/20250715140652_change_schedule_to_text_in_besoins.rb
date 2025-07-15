class ChangeScheduleToTextInBesoins < ActiveRecord::Migration[7.1]
    def up
    # Changer le type de colonne
    change_column :besoins, :schedule, :text
  end

  def down
    change_column :besoins, :schedule, :datetime
  end
end
