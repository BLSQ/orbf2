class DeleteAllPaymentRules < ActiveRecord::Migration[5.0]
  class Formula < ApplicationRecord
    belongs_to :rule, inverse_of: :formulas
  end

  class Rule < ApplicationRecord
    has_many :formulas, dependent: :destroy, inverse_of: :rule
  end

  def up
    puts "deleting payment rules #{Rule.all.where(kind: "payment").count}"
    Rule.all.where(kind: "payment").destroy_all
  end
end
