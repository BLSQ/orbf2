# == Schema Information
#
# Table name: payment_rule_datasets
#
#  id                 :bigint(8)        not null, primary key
#  desynchronized     :boolean
#  external_reference :string
#  frequency          :string
#  last_error         :string
#  last_synched_at    :datetime
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  payment_rule_id    :integer
#
# Indexes
#
#  index_payment_rule_datasets_on_payment_rule_id                (payment_rule_id)
#  index_payment_rule_datasets_on_payment_rule_id_and_frequency  (payment_rule_id,frequency) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (payment_rule_id => payment_rules.id)
#

class PaymentRuleDataset < ApplicationRecord
  include PaperTrailed
  delegate :program_id, to: :payment_rule
  delegate :project_id, to: :payment_rule

  validates :frequency, uniqueness: { scope: [:payment_rule_id] }

  belongs_to :payment_rule, inverse_of: :datasets
  attr_accessor :dataset_info, :dhis2_dataset, :diff
end
