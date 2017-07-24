# == Schema Information
#
# Table name: decision_tables
#
#  id      :integer          not null, primary key
#  rule_id :integer
#  content :text
#

class DecisionTable < ApplicationRecord
  include PaperTrailed
  delegate :project_id, to: :rule
  delegate :program_id, to: :rule

  belongs_to :rule, inverse_of: :formulas

  validate :in_headers_belong_to_facts

  validate :in_activity_code_exists

  def in_headers_belong_to_facts
    in_headers.each do |header|
      unless %w[level_1 level_2 level_3 level_4 level_5 level_6 activity_code].include?(header)
        errors[:content] << "Not in available org unit facts !"
      end
    end
  end

  def in_activity_code_exists
    return unless in_headers.include?("activity_code")
    available_codes = rule.package.activities.map(&:code).compact
    invalid_rules = decision_table.rules.reject { |rule| available_codes.include?(rule["activity_code"]) }
    invalid_rules.each { |invalid_rule| errors[:content] << "#{invalid_rule} not in available package codes #{available_codes}!" }
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

  def extra_facts(entity_facts)
    decision_table.find(entity_facts)
  end

  def decision_table
    @decision_table ||= Decision::Table.new(content || "in:nothing,out:nothing_too")
  end
end
