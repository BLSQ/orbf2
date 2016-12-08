# == Schema Information
#
# Table name: projects
#
#  id         :integer          not null, primary key
#  name       :string           not null
#  dhis2_url  :string           not null
#  user       :string
#  password   :string
#  bypass_ssl :boolean          default(FALSE)
#  boolean    :boolean          default(FALSE)
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class Project < ApplicationRecord
  validates :name, presence: true

  validates :dhis2_url, presence: true, url: true
  validates :user, presence: true
  validates :password, presence: true

  has_one :entity_group
  has_many :packages

  def verify_connection
    return { status: :ko, message: errors.full_messages.join(",") } if invalid?
    infos = dhis2_connection.system_infos.get
    return { status: :ok, message: infos }
  rescue => e
    return { status: :ko, message: e.message }
  end

  def dhis2_connection
    Dhis2::Client.new(
      url:                 dhis2_url,
      user:                user,
      password:            password,
      no_ssl_verification: bypass_ssl
    )
  end
end
