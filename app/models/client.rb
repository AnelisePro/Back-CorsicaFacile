class Client < ApplicationRecord
  devise :database_authenticatable,
         :registerable,
         :jwt_authenticatable,
         :validatable,
         jwt_revocation_strategy: Devise::JWT::RevocationStrategies::Null

  validates :first_name, presence: true
  validates :last_name, presence: true
  validates :birthdate, presence: true
  validates :phone, presence: true, format: { with: /\A(\+33|0)[1-9](\d{2}){4}\z/, message: 'doit être un numéro de téléphone valide' }
  validates :email, presence: true, uniqueness: true
  validates :avatar_url, format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]), message: "doit être une URL valide" }, allow_blank: true

  has_one_attached :avatar
  has_many :besoins, dependent: :destroy
  has_many :client_notifications, dependent: :destroy
  has_many :conversations, dependent: :destroy
  has_many :sent_messages, as: :sender, class_name: 'Message'
  has_many :received_messages, as: :recipient, class_name: 'Message'
  has_many :reviews, dependent: :destroy

  # Custom method to determine when password validation is needed
  def password_required?
    new_record? || password.present?
  end
end

