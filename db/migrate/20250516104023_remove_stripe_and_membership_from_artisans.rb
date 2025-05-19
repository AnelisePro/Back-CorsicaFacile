class RemoveStripeAndMembershipFromArtisans < ActiveRecord::Migration[7.1]
  def change
    remove_column :artisans, :membership_plan, :string
    remove_column :artisans, :stripe_customer_id, :string
    remove_column :artisans, :stripe_subscription_id, :string
  end
end
