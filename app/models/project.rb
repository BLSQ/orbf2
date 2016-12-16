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

  attr_accessor :payment_rule

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

  def export_to_json
    to_json(
      except:  [:created_at, :updated_at, :password, :user],
      include: {
        packages: {
          methods: [:rules],
          except:  [:created_at, :updated_at]
        }
      },
      methods: [:payment_rule]
    )
  end

  def dump_validations
    packages.each do |package|
      next unless package.invalid?
      puts package.errors.full_messages
      package.rules.each do |rule|
        next unless rule.invalid?
        puts "------"
        puts rule.to_json
        puts rule.available_variables_for_values.to_json
        puts rule.errors.full_messages
        rule.formulas.each do |formula|
          next unless formula.invalid?
          puts "------* *** *"
          puts formula.to_json
          puts formula.errors.full_messages
          puts rule.available_variables_for_values
        end
      end
    end
  end
end
