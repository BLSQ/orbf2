# == Schema Information
#
# Table name: activity_states
#
#  id                 :integer          not null, primary key
#  external_reference :string           not null
#  name               :string           not null
#  state_id           :integer          not null
#  activity_id        :integer          not null
#  stable_id          :uuid             not null
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#

class ActivityState < ApplicationRecord
  belongs_to :activity, inverse_of: :activity_states
  has_one :state
end
