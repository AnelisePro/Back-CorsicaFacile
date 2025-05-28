class Artisan < ApplicationRecord
  devise :database_authenticatable,
         :registerable,
         :jwt_authenticatable,
         :validatable,
         jwt_revocation_strategy: Devise::JWT::RevocationStrategies::Null

  has_one_attached :kbis
  has_one_attached :insurance
  has_one_attached :avatar

  # Nouveau : plusieurs images réalisations
  has_many_attached :project_images

  validates :company_name, :address, :expertise, :siren, :email, :phone, presence: true
  validates :siren, uniqueness: true, format: { with: /\A\d{9}\z/, message: 'doit contenir 9 chiffres' }
  validates :email, uniqueness: true
  validates :phone, format: { with: /\A(\+33|0)[1-9](\d{2}){4}\z/, message: 'doit être un numéro de téléphone valide' }
  validates :password, presence: true, confirmation: true, if: :password_required?
  validates :kbis, presence: true
  validates :insurance, presence: true
  validate :validate_file_types
  validate :validate_project_images_count

  after_save :auto_verify!

  private

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

  def validate_project_images_count
    if project_images.attached? && project_images.count > 10
      errors.add(:project_images, "Vous ne pouvez pas attacher plus de 10 images.")
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



