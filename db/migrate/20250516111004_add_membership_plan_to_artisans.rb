class AddMembershipPlanToArtisans < ActiveRecord::Migration[7.1]
  def change
    add_column :artisans, :membership_plan, :string
  end
end
