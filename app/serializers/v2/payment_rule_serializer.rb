class V2::PaymentRuleSerializer < V2::BaseSerializer
  set_type :set_group

  attributes :name do |payment_rule|
    payment_rule.rule.name
  end
  attributes :frequency

  has_many :formulas do |payment_rule|
    payment_rule.rule.formulas
  end

  attributes :stable_id do |payment_rule|
    payment_rule.rule.stable_id
  end
end
