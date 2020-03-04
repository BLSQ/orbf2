# == Schema Information
#
# Table name: activity_packages
#
#  id          :bigint(8)        not null, primary key
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  activity_id :integer          not null
#  package_id  :integer          not null
#  stable_id   :uuid             not null
#
# Indexes
#
#  index_activity_packages_on_activity_id                 (activity_id)
#  index_activity_packages_on_package_id                  (package_id)
#  index_activity_packages_on_package_id_and_activity_id  (package_id,activity_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (activity_id => activities.id)
#  fk_rails_...  (package_id => packages.id)
#

class ActivityPackage < ApplicationRecord
  include PaperTrailed
  delegate :project_id, to: :package
  delegate :program_id, to: :package

  belongs_to :package
  belongs_to :activity
end
