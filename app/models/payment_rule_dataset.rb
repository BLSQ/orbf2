class PaymentRuleDataset < ApplicationRecord
  include PaperTrailed
  delegate :program_id, to: :payment_rule
  delegate :project_id, to: :payment_rule

  belongs_to :payment_rule, inverse_of: :datasets
  attr_accessor :dataset_info, :dhis2_dataset, :diff

end
