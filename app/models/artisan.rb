class Artisan < ApplicationRecord
  devise :database_authenticatable,
         :registerable,
         :jwt_authenticatable,
         :validatable,
         jwt_revocation_strategy: Devise::JWT::RevocationStrategies::Null

  has_one_attached :kbis
  has_one_attached :insurance
  has_one_attached :avatar

  validates :company_name, presence: true
  validates :address, presence: true
  validates :expertise, presence: true
  validates :siren, presence: true, uniqueness: true, format: { with: /\A\d{9}\z/, message: 'doit contenir 9 chiffres' }
  validates :email, presence: true, uniqueness: true
  validates :phone, presence: true, format: { with: /\A(\+33|0)[1-9](\d{2}){4}\z/, message: 'doit être un numéro de téléphone valide' }
  validates :password, presence: true, confirmation: true, if: :password_required?
  validates :kbis, presence: true
  validates :insurance, presence: true
  validate :validate_file_types

  after_save :auto_verify!

  def validate_file_types
    if kbis.attached? && !kbis.content_type.in?(%w[application/pdf image/jpeg image/png])
      errors.add(:kbis, 'doit être un fichier PDF ou une image (JPEG/PNG).')
    end

    if insurance.attached? && !insurance.content_type.in?(%w[application/pdf image/jpeg image/png])
      errors.add(:insurance, 'doit être un fichier PDF ou une image (JPEG/PNG).')
    end
  end

  def password_required?
    new_record? || password.present?
  end

  def auto_verify!
    if kbis.attached? && insurance.attached?
      update_column(:verified, true) unless verified?
    end
  end
end
