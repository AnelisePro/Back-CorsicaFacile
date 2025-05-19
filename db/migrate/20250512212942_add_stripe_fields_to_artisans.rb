class AddStripeFieldsToArtisans < ActiveRecord::Migration[7.1]
  def change
    add_column :artisans, :stripe_customer_id, :string
    add_column :artisans, :stripe_subscription_id, :string
  end
end
