# == Schema Information
#
# Table name: activities
#
#  id         :integer          not null, primary key
#  item_type  :string           not null
#  item_id    :integer          not null
#  event  	  :string           not null
#  whodunnit  :string
#  object     :jsonb
#  created_at :datetime         not null


class Version < ApplicationRecord
	belongs_to :program
	belongs_to :project
end