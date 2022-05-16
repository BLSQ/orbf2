# == Schema Information
#
# Table name: programs
#
#  id                  :bigint(8)        not null, primary key
#  code                :string           not null
#  oauth_client_secret :string
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  oauth_client_id     :string
#
# Indexes
#
#  index_programs_on_code  (code) UNIQUE
#

class Program < ApplicationRecord
  has_one :project_anchor, inverse_of: :program, dependent: :destroy
  has_many :users
  has_many :versions

  def label
    "#{code} (#{id})"
  end

  def oauth_enabled?
    oauth_client_id.presence && auth_client_secret.presence
  end
end
