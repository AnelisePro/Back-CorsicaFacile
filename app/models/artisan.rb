class Artisan < ApplicationRecord
  devise :database_authenticatable,
         :registerable,
         :jwt_authenticatable,
         :validatable,
         jwt_revocation_strategy: Devise::JWT::RevocationStrategies::Null

  has_one_attached :avatar

  has_many :availability_slots, dependent: :destroy
  has_many :artisan_expertises, dependent: :destroy
  has_many :expertises, through: :artisan_expertises
  has_many :notifications, dependent: :destroy
  has_many :project_images, dependent: :destroy
  has_many :conversations, dependent: :destroy
  has_many :sent_messages, as: :sender, class_name: 'Message'
  has_many :received_messages, as: :recipient, class_name: 'Message'

  # === VALIDATIONS ===
  validates :company_name, :address, :siren, :email, :phone, presence: true
  validates :kbis_url, presence: true, on: :create
  validates :insurance_url, presence: true, on: :create
  validate :must_have_at_least_one_expertise, if: :persisted?
  validates :siren, uniqueness: true, format: { with: /\A\d{9}\z/, message: 'doit contenir 9 chiffres' }
  validates :email, uniqueness: true
  validates :phone, format: { with: /\A(\+33|0)[1-9](\d{2}){4}\z/, message: 'doit être un numéro de téléphone valide' }
  validates :password, presence: true, confirmation: true, if: :password_required?

  after_save :auto_verify!
  before_validation :set_subscription_started_at, on: :create

  private

  def must_have_at_least_one_expertise
    errors.add(:expertises, "doit avoir au moins une expertise") if expertises.blank?
  end

  def password_required?
    new_record? || password.present?
  end

  def auto_verify!
    if kbis_url.present? && insurance_url.present?
      update_column(:verified, true) unless verified?
    end
  end

  def set_subscription_started_at
    self.subscription_started_at ||= Time.current
  end
end








