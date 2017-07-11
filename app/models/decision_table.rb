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

  def in_headers_belong_to_facts
    in_headers.each do |header|
      unless %w[level_1 level_2 level_3 level_4 level_5 level_6].include?(header)
        errors[:content] << "Not in available org unit facts !"
      end
    end
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
