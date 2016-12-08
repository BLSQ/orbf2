# == Schema Information
#
# Table name: states
#
#  id   :integer          not null, primary key
#  name :string           not null
#

class State < ApplicationRecord
  validates :name, presence: true
end
