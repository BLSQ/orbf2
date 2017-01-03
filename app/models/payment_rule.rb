# == Schema Information
#
# Table name: payment_rules
#
#  id         :integer          not null, primary key
#  project_id :integer          not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class PaymentRule < ApplicationRecord
  belongs_to :project, inverse_of: :payment_rules
  has_one :rule, dependent: :destroy, inverse_of: :payment_rule
  has_many :package_payment_rules, dependent: :destroy

  has_many :packages, through: :package_payment_rules, source: :package


  accepts_nested_attributes_for :rule, allow_destroy: true
  accepts_nested_attributes_for :package_payment_rules, reject_if: :all_blank, allow_destroy: true
end
