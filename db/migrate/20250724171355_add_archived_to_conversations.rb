class AddArchivedToConversations < ActiveRecord::Migration[7.1]
  def change
    add_column :conversations, :archived, :boolean, default: false
  end
end
