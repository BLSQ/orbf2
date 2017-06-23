# == Schema Information
#
# Table name: activity_packages
#
#  id          :integer          not null, primary key
#  activity_id :integer          not null
#  package_id  :integer          not null
#  stable_id   :uuid             not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#

class ActivityPackage < ApplicationRecord
  include PaperTrailed

  belongs_to :package
  belongs_to :activity

end
