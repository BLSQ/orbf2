# == Schema Information
#
# Table name: package_payment_rules
#
#  id              :integer          not null, primary key
#  package_id      :integer          not null
#  payment_rule_id :integer          not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#

class PackagePaymentRule < ApplicationRecord
  include PaperTrailed

  belongs_to :package
  belongs_to :package_payment_rules, inverse_of: :rule
end
