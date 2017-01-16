# == Schema Information
#
# Table name: project_anchors
#
#  id         :integer          not null, primary key
#  program_id :integer          not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class ProjectAnchor < ApplicationRecord
  belongs_to :program
  has_many :projects, inverse_of: :project_anchor, dependent: :destroy

  def invalid_project?
    project.nil? || project.invalid?
  end

  def project
    projects.first
  end
end
