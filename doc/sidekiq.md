Queues:
- critical
- dhis2-safe
- default

create_dhis2_element_for_formula_mapping_worker.rb
  Fast

create_dhis2_element_worker.rb
  Abstract (but could set queu for create_dhis2 and create_missing_dhis2)
  queue: critical

create_missing_dhis2_element_for_activity_worker.rb
  Fast

dhis2_analytics_worker.rb
  Fast (analytics is slow, but triggering it is fast)
  queues: critical

dhis2_snapshot_compactor.rb
  PORO used in worker
dhis2_snapshot_worker.rb
  Snapshot per project
  queues: critical

discard_invoicing_job_worker.rb
  Fast (cleans up orphaned tasks)

invoice_for_project_anchor_worker.rb
  queue: default

invoice_simulation_worker.rb
  queue is dhis2_safe

output_dataset_worker.rb
  queues: critical

project_coc_aoc_reference_worker.rb
  queues: critical

synchronise_deg_ds_worker.rb
  queues: critical

synchronise_groups_worker.rb
  queues: critical

update_metadata_worker.rb
  queues: critical
