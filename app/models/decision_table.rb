# frozen_string_literal: true
# == Schema Information
#
# Table name: decision_tables
#
#  id           :bigint(8)        not null, primary key
#  comment      :text
#  content      :text
#  end_period   :string
#  name         :string
#  source_url   :string
#  start_period :string
#  rule_id      :integer
#
# Indexes
#
#  index_decision_tables_on_rule_id  (rule_id)
#
# Foreign Keys
#
#  fk_rails_...  (rule_id => rules.id)
#

class DecisionTable < ApplicationRecord
  include PaperTrailed
  delegate :project_id, to: :rule
  delegate :program_id, to: :rule

  belongs_to :rule, inverse_of: :decision_tables

  validate :in_headers_belong_to_facts

  validate :in_activity_code_exists

  validate :period_start_before_end

  # keep start/end period nil if empty
  before_save :normalize_blank_values

  def normalize_blank_values
    %w[start_period end_period].each do |column|
      self[column].present? || self[column] = nil
    end
  end

  HEADER_PREFIXES = %w[level_1 level_2 level_3 level_4 level_5 level_6 level activity_code].freeze
  HEADER_IN_ACTIVITY_CODE = "in:activity_code"

  def in_headers_belong_to_facts
    in_headers.each do |header|
      unless HEADER_PREFIXES.include?(header) || header.starts_with?("groupset_code_")
        errors[:content] << "Not '#{header}' in available org unit facts !"
      end
    end
  end

  def in_activity_code_exists
    return unless in_headers.include?("activity_code")

    available_codes = rule.package.activity_packages.map(&:activity).map(&:code).compact
    available_codes.push Decision::Rule::ANY
    invalid_rules = decision_table.rules.reject { |rule| available_codes.include?(rule[HEADER_IN_ACTIVITY_CODE]) }
    invalid_rules.each { |invalid_rule| errors[:content] << "#{invalid_rule.inspect} not in available package codes #{available_codes}!" }
  end

  def period_start_before_end
    # both empty, validate nothing
    return if !start_period.presence && !end_period.presence

    if start_period.presence && !end_period.presence
      errors[:end_period] << "Should be filled in if start period is filled"
    elsif !start_period.presence && end_period.presence
      errors[:start_period] << "Should be filled in if end period is filled"
    else
      if start_period.presence > end_period.presence
        errors[:start_period] << "Should be before end period"
      end

      package_frequency = rule.package.frequency

      validate_period_type(start_period, :start_period, package_frequency)
      validate_period_type(end_period, :end_period, package_frequency)
    end
  end

  def validate_period_type(value, field, expected_frequency)
    frequency = Periods.detect(value)
    if frequency != expected_frequency
      errors[field] << "Should be of period type " + expected_frequency
    end
  rescue StandardError => e
    errors[field] << "Should be of period type " + expected_frequency + " : " + e.message
  end

  def in_headers
    decision_table.headers(:in)
  end

  def out_headers
    decision_table.headers(:out)
  end

  def content=(content)
    super
    @decision_table = nil
  end

  def decision_table
    @decision_table ||= Decision::Table.new(content || "in:nothing,out:nothing_too")
  end

  def formatted_name
    name ? name : "Decision table - " + id.to_s
  end
end
