# == Schema Information
#
# Table name: states
#
#  id         :integer          not null, primary key
#  name       :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class State < ApplicationRecord
  validates :name, presence: true
end
