# frozen_string_literal: true

# == Schema Information
#
# Table name: payment_rules
#
#  id         :bigint(8)        not null, primary key
#  frequency  :string           default("quarterly"), not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  project_id :integer          not null
#
# Indexes
#
#  index_payment_rules_on_project_id  (project_id)
#
# Foreign Keys
#
#  fk_rails_...  (project_id => projects.id)
#

class PaymentRule < ApplicationRecord
  include PaperTrailed
  delegate :program_id, to: :project

  FREQUENCIES = %w[monthly quarterly].freeze

  belongs_to :project, inverse_of: :payment_rules
  has_one :rule, dependent: :destroy, inverse_of: :payment_rule
  has_many :package_payment_rules, dependent: :destroy
  has_many :packages, through: :package_payment_rules, source: :package
  has_many :datasets, dependent:  :destroy,
                      class_name: "PaymentRuleDataset",
                      inverse_of: "payment_rule"

  accepts_nested_attributes_for :rule, allow_destroy: true

  validates :frequency, presence: true, inclusion: {
    in:      FREQUENCIES,
    message: "%{value} is not a valid see #{FREQUENCIES.join(',')}"
  }

  def dataset(given_frequency)
    datasets.detect { |ds| ds.frequency == given_frequency }
  end

  def code
    @code ||= Orbf::RulesEngine::Codifier.codify(rule.name)
  end

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
