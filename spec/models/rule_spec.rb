# == Schema Information
#
# Table name: rules
#
#  id              :integer          not null, primary key
#  name            :string           not null
#  kind            :string           not null
#  package_id      :integer
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  payment_rule_id :integer
#  stable_id       :uuid             not null
#

