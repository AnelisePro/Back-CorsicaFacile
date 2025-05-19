class AddAuthenticationTokenToArtisans < ActiveRecord::Migration[7.1]
  def change
    add_column :artisans, :authentication_token, :string
  end
end
