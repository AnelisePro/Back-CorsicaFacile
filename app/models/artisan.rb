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
  has_many :reviews, dependent: :destroy

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

  # Constantes pour les limites de réponses
  RESPONSE_LIMITS = {
    'Standard' => 3,
    'Pro' => 6,
    'Premium' => nil # illimité
  }.freeze

  def can_respond_to_announcement?
    return false unless verified? && !banned?
    return true if membership_plan == 'Premium' # Illimité

    monthly_response_count < response_limit
  end

  def response_limit
    limit = RESPONSE_LIMITS[membership_plan]
    if limit.nil? && membership_plan != 'Premium'
      Rails.logger.warn "Membership plan invalide ou manquant : #{membership_plan}"
    end
    limit || 0
  end

  def remaining_responses
    return Float::INFINITY if membership_plan == 'Premium'

    [response_limit - monthly_response_count, 0].max
  end

  def increment_response_count!
    puts "Avant reset: monthly_response_count = #{monthly_response_count}"
    reset_monthly_counter_if_needed
    reload
    puts "Après reset/reload: monthly_response_count = #{monthly_response_count}"
    puts "can_respond_to_announcement? = #{can_respond_to_announcement?}"
    puts "verified? = #{verified?}, banned? = #{banned?}"
    puts "membership_plan = #{membership_plan}, response_limit = #{response_limit}"
    
    if can_respond_to_announcement?
      puts "Incrémentation en cours..."
      increment!(:monthly_response_count)
      puts "Après incrémentation: monthly_response_count = #{monthly_response_count}"
      true
    else
      puts "Ne peut pas répondre"
      false
    end
  end

  def responses_used_percentage
    return 0 if membership_plan == 'Premium'
    return 100 if response_limit == 0
    
    reset_monthly_counter_if_needed
    ((monthly_response_count.to_f / response_limit) * 100).round(1)
  end

  def next_reset_date
    Time.current.end_of_month + 1.second
  end

  def reset_monthly_counter_if_needed
    current_month = Time.current.beginning_of_month
    return if last_response_reset_at.present? &&
              last_response_reset_at >= current_month

    update!(
      monthly_response_count: 0,
      last_response_reset_at: current_month
    )
  end

  def average_rating
    reviews.average(:rating)&.round(1) || 0
  end

  def total_reviews
    reviews.count
  end

    # Méthodes pour la gestion du bannissement
  def banned?
    banned_at.present?
  end

  def ban!(admin_id)
    update!(banned_at: Time.current, banned_by: admin_id)
  end

  def unban!
    update!(banned_at: nil, banned_by: nil)
  end

  def banned_by_admin
    Admin.find(banned_by) if banned_by.present?
  end

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








