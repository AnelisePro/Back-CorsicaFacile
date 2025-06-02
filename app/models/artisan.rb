class Artisan < ApplicationRecord
  devise :database_authenticatable,
         :registerable,
         :jwt_authenticatable,
         :validatable,
         jwt_revocation_strategy: Devise::JWT::RevocationStrategies::Null

  has_one_attached :kbis
  has_one_attached :insurance
  has_one_attached :avatar

  has_many_attached :project_images
  has_many :availability_slots, dependent: :destroy
  has_many :artisan_expertises, dependent: :destroy
  has_many :expertises, through: :artisan_expertises

  validates :company_name, :address, :siren, :email, :phone, presence: true
  validate :must_have_at_least_one_expertise, if: :persisted?
  validates :siren, uniqueness: true, format: { with: /\A\d{9}\z/, message: 'doit contenir 9 chiffres' }
  validates :email, uniqueness: true
  validates :phone, format: { with: /\A(\+33|0)[1-9](\d{2}){4}\z/, message: 'doit être un numéro de téléphone valide' }
  validates :password, presence: true, confirmation: true, if: :password_required?

  # Validation présence uniquement à la création
  validates :kbis, presence: true, on: :create
  validates :insurance, presence: true, on: :create

  validate :validate_file_types

  after_save :auto_verify!

  private

  def must_have_at_least_one_expertise
    errors.add(:expertises, "doit avoir au moins une expertise") if expertises.blank?
  end

  def validate_file_types
    if kbis.attached? && !kbis.content_type.in?(%w[application/pdf image/jpeg image/png])
      errors.add(:kbis, 'doit être un fichier PDF ou une image (JPEG/PNG).')
    end

    if insurance.attached? && !insurance.content_type.in?(%w[application/pdf image/jpeg image/png])
      errors.add(:insurance, 'doit être un fichier PDF ou une image (JPEG/PNG).')
    end

    if project_images.attached?
      project_images.each do |img|
        unless img.content_type.in?(%w[image/jpeg image/png])
          errors.add(:project_images, 'doivent être des images JPEG ou PNG.')
        end
      end
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




