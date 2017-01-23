# == Schema Information
#
# Table name: projects
#
#  id                :integer          not null, primary key
#  name              :string           not null
#  dhis2_url         :string           not null
#  user              :string
#  password          :string
#  bypass_ssl        :boolean          default(FALSE)
#  boolean           :boolean          default(FALSE)
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  program_id        :integer          not null
#  status            :string           default("draft"), not null
#  publish_date      :datetime
#  project_anchor_id :integer
#

class Project < ApplicationRecord
  validates :name, presence: true

  validates :dhis2_url, presence: true, url: true
  validates :user, presence: true
  validates :password, presence: true

  has_one :entity_group, dependent: :destroy
  has_many :packages, dependent: :destroy
  has_many :payment_rules, dependent: :destroy
  belongs_to :project_anchor
  belongs_to :original, foreign_key: "original_id", optional: true, class_name: Project.name
  has_many :clones, foreign_key: "original_id", class_name: Project.name

  def self.latests
    order("id desc").limit(10)
  end

  def draft?
    status == "draft"
  end

  def published?
    status == "published"
  end

  def publish(date)
    raise "already published !" unless draft?
    old_project = self
    new_project = nil
    transaction do
      new_project = deep_clone include: {
        entity_group:  [],
        packages:      {
          package_entity_groups: [],
          package_states:        [],
          rules:                 [
            :formulas
          ]
        },
        payment_rules: {
          package_payment_rules: [],
          rule:                  [
            :formulas
          ]
        }
      } # do |original, kopy|
      #  puts "cloning #{original} #{kopy}"
      # end
      new_project.original = old_project
      new_project.save!

      old_project.publish_date = date
      old_project.status = "published"
      old_project.save!
    end
    new_project
  end

  def at_least_one_package_rule
    packages.any? { |p| p.rules.size == 2 }
  end

  def missing_rules_kind
    payment_rule ? [] : ["payment"]
  end

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

  def unused_packages
    packages.select do |package|
      payment_rules.none? { |payment_rule| payment_rule.packages.include?(package) }
    end
  end

  def export_to_json
    to_json(
      except:  [:created_at, :updated_at, :password, :user],
      include: {
        payment_rules: {
          rule: {
            include: {
              formulas: {}
            }
          }
        },
        packages:      {
          except:  [:created_at, :updated_at],
          include: {
            rules: {
              include: {
                formulas: {}
              }
            }
          }
        }
      }
    )
  end

  def to_unified_h
    {
      entity_group:  {
        external_reference: entity_group.external_reference,
        name:               entity_group.name
      },
      packages:      Hash[packages.map(&:to_unified_h).map { |h| [h[:stable_id], h] }],
      payment_rules: Hash[payment_rules.map(&:to_unified_h).map { |h| [h[:stable_id], h] }]
    }
  end

  def to_unified_names
    Hash[packages.map(&:to_unified_h).map { |h| [h[:stable_id], h[:name]] }].merge(
      Hash[payment_rules.map(&:to_unified_h).map { |h| [h[:stable_id], h[:name]] }]
    ).merge(
      Hash[packages.flat_map(&:rules).map(&:to_unified_h).map {|h| [h[:stable_id], h[:name]] }]
    )
  end

  def dump_validations
    payment_rules.each do |payment_rule|
      puts "payment_rule #{payment_rule.valid?} #{payment_rule.errors.full_messages}"
      puts "payment_rule #{payment_rule.packages.first}"
      next unless payment_rule.rule.invalid?

      dump_validation_rule(payment_rule.rule)
    end
    packages.each do |package|
      next unless package.invalid?
      puts package.errors.full_messages
      package.rules.each do |rule|
        dump_validation_rule(rule)
      end
    end
  end

  def dump_validation_rule(rule)
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

  def dump_rules
    packages.each do |package|
      puts "**** #{package.name} #{package.frequency}"
      package.rules.each do |rule|
        puts "------ Rule #{rule.name} #{rule.kind}"
        rule.formulas.each do |formula|
          puts [formula.code, formula.description, formula.expression].join("\t")
        end
      end
    end
end
end
