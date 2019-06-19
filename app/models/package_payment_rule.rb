# == Schema Information
#
# Table name: package_payment_rules
#
#  id              :bigint(8)        not null, primary key
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  package_id      :integer          not null
#  payment_rule_id :integer          not null
#
# Indexes
#
#  index_package_payment_rules_on_package_id       (package_id)
#  index_package_payment_rules_on_payment_rule_id  (payment_rule_id)
#
# Foreign Keys
#
#  fk_rails_...  (package_id => packages.id)
#  fk_rails_...  (payment_rule_id => payment_rules.id)
#

class PackagePaymentRule < ApplicationRecord
  include PaperTrailed
  delegate :project_id, to: :package
  delegate :program_id, to: :package

  belongs_to :package
  belongs_to :payment_rule, inverse_of: :package_payment_rules
end
