# == Schema Information
#
# Table name: users
#
#  id                     :integer          not null, primary key
#  current_sign_in_at     :datetime
#  current_sign_in_ip     :inet
#  email                  :string           default(""), not null
#  encrypted_password     :string           default(""), not null
#  last_sign_in_at        :datetime
#  last_sign_in_ip        :inet
#  remember_created_at    :datetime
#  reset_password_sent_at :datetime
#  reset_password_token   :string
#  sign_in_count          :integer          default(0), not null
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  program_id             :integer
#
# Indexes
#
#  index_users_on_email                 (email) UNIQUE
#  index_users_on_program_id            (program_id)
#  index_users_on_reset_password_token  (reset_password_token) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (program_id => programs.id)
#

class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable,
         :recoverable, :rememberable, :trackable, :validatable

  validates :email,
            format: { with:    /\A.*@bluesquare.org\z/,
                      message: "Sorry, restricted signup" },
            if:     :env_dev?

  belongs_to :program, optional: true

  def env_dev?
    Rails.env.dev?
  end

  def label
    "User##{id} - #{email}"
  end

  def impersonate_label
    project = program&.project_anchor&.project
    if project
      [id, email, project.name, project.id].join(" - ")
    else
      [id, email, "No project assigned"].join(" - ")
    end
  end

  def flipper_id
    "User:#{id}"
  end
end
