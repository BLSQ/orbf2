class ChangeIdToBigInts < ActiveRecord::Migration[5.2]
  def change
    %i[
      activities
      activity_packages
      activity_states
      decision_tables
      dhis2_logs
      dhis2_snapshot_changes
      dhis2_snapshots
      entity_groups
      formula_mappings
      formulas
      invoicing_jobs
      package_entity_groups
      package_payment_rules
      package_states
      packages
      payment_rule_datasets
      payment_rules
      programs
      project_anchors
      projects
      rules
      states
      users
      version_associations
      versions
    ].each do |table|
      change_column table, :id, :bigint
    end
  end
end
