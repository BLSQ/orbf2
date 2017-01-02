# == Schema Information
#
# Table name: states
#
#  id           :integer          not null, primary key
#  name         :string           not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  configurable :boolean          default(FALSE), not null
#  level        :string
#

class State < ApplicationRecord
  validates :name, presence: true

  def self.configurables(conf = "")
    if conf == ""
      where("configurable= ? OR configurable= ?", true, false)
    else
      where configurable: conf
    end
  end

  def code
    name.parameterize("_")
  end

  def package_level?
    level == "package"
  end

  def activity_level?
    level == "activity"
  end
end
