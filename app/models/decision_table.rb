class DecisionTable < ApplicationRecord
  belongs_to :rule, inverse_of: :formulas

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

  private

  def decision_table
    @decision_table ||= Decision::Table.new(content || 'in:nothing,out:nothing_too')
  end
end
