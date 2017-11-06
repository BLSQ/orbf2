# == Schema Information
#
# Table name: payment_rules
#
#  id         :integer          not null, primary key
#  project_id :integer          not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  frequency  :string           default("quarterly"), not null
#

class PaymentRule < ApplicationRecord
  include PaperTrailed
  delegate :program_id, to: :project

  FREQUENCIES = %w[monthly quarterly].freeze

  belongs_to :project, inverse_of: :payment_rules
  has_one :rule, dependent: :destroy, inverse_of: :payment_rule
  has_many :package_payment_rules, dependent: :destroy

  has_many :packages, through: :package_payment_rules, source: :package
  accepts_nested_attributes_for :rule, allow_destroy: true

  validates :frequency, presence: true, inclusion: {
    in:      FREQUENCIES,
    message: "%{value} is not a valid see #{FREQUENCIES.join(',')}"
  }

  def quarterly?
    for_frequency("quarterly")
  end

  def monthly?
    for_frequency("monthly")
  end

  def for_frequency(frequency_to_apply)
    frequency_to_apply == frequency
  end

  def apply_for?(entity)
    packages.all? { |p| p.apply_for(entity) }
  end

  def to_unified_h
    {
      stable_id: rule.stable_id,
      name:      rule.name,
      packages:  Hash[package_payment_rules.map(&:package).map(&:stable_id).map { |stable_id| [stable_id, stable_id] }],
      rule:      rule.to_unified_h
    }
  end
end
