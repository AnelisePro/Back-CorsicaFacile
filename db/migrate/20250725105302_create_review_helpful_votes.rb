class CreateReviewHelpfulVotes < ActiveRecord::Migration[7.1]
  def change
    create_table :review_helpful_votes do |t|
      t.references :review, null: false, foreign_key: true
      
      # Relations polymorphiques pour Client OU Artisan
      t.references :voter, polymorphic: true, null: false, index: true

      t.timestamps
    end

    add_index :review_helpful_votes, [:review_id, :voter_type, :voter_id], 
              unique: true, name: 'index_review_votes_unique'
  end
end
