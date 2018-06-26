# == Schema Information
#
# Table name: payment_rule_datasets
#
#  id                 :integer          not null, primary key
#  payment_rule_id    :integer
#  frequency          :string
#  external_reference :string
#  last_synched_at    :datetime
#  last_error         :string
#  desynchronized     :boolean
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#

class PaymentRuleDataset < ApplicationRecord
  include PaperTrailed
  delegate :program_id, to: :payment_rule
  delegate :project_id, to: :payment_rule

  validates :frequency, uniqueness: { scope: [:payment_rule_id] }

  belongs_to :payment_rule, inverse_of: :datasets
  attr_accessor :dataset_info, :dhis2_dataset, :diff
end
