class Admin < ApplicationRecord
  devise :database_authenticatable, :jwt_authenticatable,
         :registerable, 
         jwt_revocation_strategy: Devise::JWT::RevocationStrategies::Null
  
  validates :email, presence: true, uniqueness: true
  validates :role, inclusion: { in: %w[super_admin admin] }
end