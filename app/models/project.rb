# frozen_string_literal: true
# == Schema Information
#
# Table name: projects
#
#  id                    :bigint(8)        not null, primary key
#  boolean               :boolean          default(FALSE)
#  bypass_ssl            :boolean          default(FALSE)
#  calendar_name         :string           default("gregorian"), not null
#  cycle                 :string           default("quarterly"), not null
#  default_aoc_reference :string
#  default_coc_reference :string
#  dhis2_url             :string           not null
#  engine_version        :integer          default(3), not null
#  name                  :string           not null
#  password              :string
#  publish_date          :datetime
#  publish_end_date      :datetime
#  qualifier             :string
#  status                :string           default("draft"), not null
#  user                  :string
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  original_id           :integer
#  project_anchor_id     :integer
#
# Indexes
#
#  index_projects_on_project_anchor_id  (project_anchor_id)
#
# Foreign Keys
#
#  fk_rails_...  (original_id => projects.id)
#  fk_rails_...  (project_anchor_id => project_anchors.id)
#

class Project < ApplicationRecord
  CYCLES = %w[quarterly yearly].freeze
  # keep this one at the top or might not work as expected
  before_destroy :destroy_dependencies

  has_paper_trail meta: {
    project_id: :id,
    program_id: :program_id,
    item_type:  "Project",
    item_id:    :id
  }

  delegate :program_id, to: :project_anchor
  has_many :states, dependent: :destroy
  has_many :payment_rules, dependent: :destroy
  has_one :entity_group, dependent: :destroy
  has_many :packages, dependent: :destroy
  has_many :activities, dependent: :destroy, inverse_of: :project
  belongs_to :project_anchor
  belongs_to :original, foreign_key: "original_id", optional: true, class_name: Project.name
  has_many :clones, foreign_key: "original_id", class_name: Project.name, dependent: :destroy
  has_many :versions, dependent: :destroy

  validates :name, presence: true
  validates :dhis2_url, presence: true, url: true
  validates :user, presence: true
  validates :password, presence: true
  validates :cycle, presence: true, inclusion: {
    in:      CYCLES,
    message: "%{value} is not a valid see #{CYCLES.join(',')}"
  }

  ENGINE_VERSIONS = [2, 3].freeze

  validates :engine_version, presence: true, inclusion: {
    in:      ENGINE_VERSIONS,
    message: "%{value} is not a valid see #{ENGINE_VERSIONS.join(',')}"
  }

  PACKAGE_INCLUDES = {
    activities:            {
      activity_states: [:state]
    },
    activity_packages:     {
      activity: {
        activity_states: [:state]
      }
    },
    package_entity_groups: {

    },
    states:                {
    },
    package_states:        {
      state: []
    },
    rules:                 {
      decision_tables: [],
      formulas:        {
        rule:             [:formulas],
        formula_mappings: [:activity]
      },
      payment_rule:    {}
    }
  }


  def contract_settings
    if entity_group.contract_program_based?
      {
        program_id: entity_group.program_reference,
        all_event_sql_view_id: entity_group.all_event_sql_view_reference
      }
    end
  end

  # see PaperTrailed meta
  def project_id
    id
  end

  def item_type
    "Project"
  end

  def engine_version_enum
    { "2.0 - dentaku" => 2, "3.0 - golang" => 3 }
  end

  def cycle_yearly?
    cycle == "yearly"
  end

  def calendar
    @calendar ||= if calendar_name == "ethiopian"
                    Orbf::RulesEngine::EthiopianCalendar.new
                  else
                    Orbf::RulesEngine::GregorianCalendar.new
                  end
  end

  def state(code)
    states.find { |state| state.code == code.to_s }
  end

  def package(code)
    packages.find { |package| package.code == code }
  end

  def naming_patterns
    @naming_patterns ||= {
      long:  "#{clean_qualifier} - %{state_short_name} - %{activity_code} %{activity_name}",
      short: "%{activity_short_name} (%{state_short_name}%{activity_code})",
      code:  "%{raw_activity_code} - %{state_code}"
    }
  end

  def naming_patterns_without_activity
    @naming_patterns_without_activity ||= begin
      {
        long:  "#{clean_qualifier} - %{state_short_name}",
        short: "%{state_short_name}",
        code:  "%{state_code}"
      }
    end
  end

  def clean_qualifier
    q = qualifier.presence ? qualifier.strip : nil
    q || "RBF"
  end

  def self.no_includes
    current_scope
  end

  def self.fully_loaded


    includes(
      packages:      PACKAGE_INCLUDES,
      activities:    {
        activity_states:   [:state],
        activity_packages: { package: PACKAGE_INCLUDES }
      },
      payment_rules: {
        package_payment_rules: {
          package: PACKAGE_INCLUDES
        },
        packages:              PACKAGE_INCLUDES,
        rule:                  {
          decision_tables: [],
          formulas:        {
            rule:             [:formulas],
            formula_mappings: [:activity]
          },
          payment_rule:    {}
        }
      }
    )
  end

  def self.for_date(date)
    where(status: "published")
      .where("projects.publish_date <= ?", date)
      .where("projects.publish_end_date is null OR projects.publish_end_date >= ?", date)
      .order("projects.publish_date desc")
      .limit(1)
      .first
  end

  def self.latests
    order("id desc").limit(10)
  end

  def new_engine?
    engine_version >= 2
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
      new_project = deep_clone(
        include: {
          states:        [],
          entity_group:  [],
          activities:    {
            activity_states: [:state]
          },
          packages:      {
            package_entity_groups: [],
            package_states:        [:state],
            rules:                 [
              :decision_tables,
              formulas: { formula_mappings: [:activity] }
            ],
            activity_packages:     [:activity]
          },
          payment_rules: {
            package_payment_rules: [:package],
            rule:                  [
              :decision_tables,
              formulas: { formula_mappings: [:activity] }
            ],
            datasets:              []
          }
        }, use_dictionary: true
      )
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

  def payment_rule_for_code(code)
    payment_rules.detect { |pr| pr.code == code }
  end

  def verify_connection
    return { status: :ko, message: errors.full_messages.join(",") } if invalid?

    infos = dhis2_connection.system_infos.get
    { status: :ok, message: infos }
  rescue StandardError => e
    { status: :ko, message: e.message }
  end

  def dhis2_connection
    Dhis2::Client.new(dhis_configuration)
  end

  def dhis_configuration
    {
      url:                 dhis2_url,
      user:                user,
      password:            password,
      no_ssl_verification: bypass_ssl,
      debug:               false
    }
  end

  def unused_packages
    packages.select do |package|
      payment_rules.none? { |payment_rule| payment_rule.packages.include?(package) }
    end
  end

  def export_to_json
    to_json(
      except:  %i[created_at updated_at password user],
      include: {
        payment_rules: {
          rule: {
            include: {
              formulas: {}
            }
          }
        },
        packages:      {
          except:  %i[created_at updated_at],
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
      states:        states.map(&:to_unified_h).map { |h| [h[:stable_id], h] }.to_h,
      entity_group:  {
        external_reference: entity_group ? entity_group.external_reference : "",
        name:               entity_group ? entity_group.name : ""
      },
      activities:    Hash[activities.map(&:to_unified_h).map { |h| [h[:stable_id], h] }],
      packages:      Hash[packages.map(&:to_unified_h).map { |h| [h[:stable_id], h] }],
      payment_rules: Hash[payment_rules.map(&:to_unified_h).map { |h| [h[:stable_id], h] }]
    }
  end

  def to_unified_names
    Hash[packages.map(&:to_unified_h).map { |h| [h[:stable_id], h[:name]] }].merge(
      Hash[payment_rules.map(&:to_unified_h).map { |h| [h[:stable_id], h[:name]] }]
    ).merge(
      Hash[packages.flat_map(&:rules).map(&:to_unified_h).map { |h| [h[:stable_id], h[:name]] }]
    ).merge(
      Hash[activities.flat_map(&:activity_states).map(&:to_unified_h).map { |h| [h[:stable_id], h[:name]] }]
    ).merge(
      Hash[activities.map(&:to_unified_h).map { |h| [h[:stable_id], h[:name]] }]
    )
  end

  def changelog(other_project = original)
    return [] unless other_project

    diff_symbols = { "+" => :added, "-" => :removed, "~" => :modified }
    all_names = to_unified_names.merge(other_project.to_unified_names)
    HashDiff.diff(other_project.to_unified_h, to_unified_h).map do |hash_diff|
      operation, path, value, current = hash_diff

      ChangelogEntry.new(
        operation:           diff_symbols[operation],
        path:                hash_diff[1],
        human_readable_path: replace_stable_id(all_names, path),
        current_value:       replace_stable_id(all_names, current),
        previous_value:      replace_stable_id(all_names, value),
        show_detail:         value.is_a?(String) || current.is_a?(String)
      )
    end
  end

  def replace_stable_id(all_names, path)
    return nil if path.nil?
    return path unless path.is_a?(String)

    all_names.each do |uuid, name|
      path = path.gsub(".#{uuid}.", " '#{name}' ")
      path = path.gsub(".#{uuid}", " '#{name}' ")
      path = path.gsub(uuid.to_s, " '#{name}' ")
    end
    path
  end

  def dump_validations
    payment_rules.each do |payment_rule|
      log "payment_rule #{payment_rule.valid?} #{payment_rule.errors.full_messages}"
      log "payment_rule #{payment_rule.packages.first}"
      next unless payment_rule.rule.invalid?

      dump_validation_rule(payment_rule.rule)
    end
    packages.each do |package|
      next unless package.invalid?

      log package.errors.full_messages
      package.rules.each do |rule|
        dump_validation_rule(rule)
      end
    end
  end

  def formula_mappings
    rules = packages.map(&:rules) + payment_rules.map(&:rule)
    rules.flatten.flat_map(&:formulas).flat_map(&:formula_mappings)
  end

  def dump_validation_rule(rule)
    log "------"
    log rule.to_json
    log rule.available_variables_for_values.to_json
    log rule.errors.full_messages
    rule.formulas.each do |formula|
      next unless formula.invalid?

      log "------* *** *"
      log formula.to_json
      log formula.errors.full_messages
      log rule.available_variables_for_values
    end
  end

  def dump_rules
    packages.each do |package|
      log "**** #{package.name} #{package.frequency}"
      package.rules.each do |rule|
        log "------ Rule #{rule.name} #{rule.kind}"
        rule.formulas.each do |formula|
          log [formula.code, formula.description, formula.expression].join("\t")
        end
      end
    end
  end

  def missing_activity_states
    missing_activity_states = {}
    packages.each do |package|
      package_missing_states = package.missing_activity_states
      package_missing_states.each do |activity, states|
        missing_activity_states[activity] ||= []
        missing_activity_states[activity] += states
      end
    end
    missing_activity_states
  end

  private

  def destroy_dependencies
    payment_rules.destroy_all
    packages.destroy_all
    activities.destroy_all
  end

  def log(message)
    Rails.logger.debug message
  end
end
