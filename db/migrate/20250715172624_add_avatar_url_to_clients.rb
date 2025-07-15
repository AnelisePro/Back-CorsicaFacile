class AddAvatarUrlToClients < ActiveRecord::Migration[7.1]
  def change
    add_column :clients, :avatar_url, :string
  end
end
