# == Schema Information
#
# Table name: programs
#
#  id         :integer          not null, primary key
#  code       :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class Program < ApplicationRecord
  has_one :project_anchor, inverse_of: :program, dependent: :destroy
  has_many :users
  has_many :versions
end
