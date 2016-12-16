class RenameRulesIdToRuleIdOnRulesTable < ActiveRecord::Migration[5.0]
  def change
    rename_column :formulas, :rules_id, :rule_id
  end
end
