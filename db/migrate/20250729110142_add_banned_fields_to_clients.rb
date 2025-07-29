class AddBannedFieldsToClients < ActiveRecord::Migration[7.1]
  def change
    add_column :clients, :banned_at, :datetime
    add_column :clients, :banned_by, :integer
  end
end
