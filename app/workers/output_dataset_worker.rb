# frozen_string_literal: true

class OutputDatasetWorker
  include Sidekiq::Worker

  sidekiq_options retry: 0

  ADD_MISSING_DE = "add_missing_de"
  ADD_MISSING_OU = "add_missing_ou"
  REMOVE_EXTRA_DE = "remove_extra_de"
  REMOVE_EXTRA_OU = "remove_extra_ou"

  MODES = [ADD_MISSING_DE, ADD_MISSING_OU, REMOVE_EXTRA_DE, REMOVE_EXTRA_OU].freeze

  MODE_OPTIONS = [
    ["Add missing data elements", ADD_MISSING_DE],
    ["Remove extra data elements", REMOVE_EXTRA_DE],
    ["Add missing orgunits", ADD_MISSING_OU],
    ["Remove extra org units", REMOVE_EXTRA_OU]
  ].freeze

  def perform(project_id, payment_rule_code, frequency, options)
    modes = options.fetch("modes")
    @legacy_project = Project.find(project_id)

    Datasets::BuildDatasets.new(legacy_project).call

    @payment_rule = legacy_project.payment_rule_for_code(payment_rule_code)
    dataset = payment_rule.dataset(frequency)
    begin
      dhis2_dataset = load_dhis2_dataset(dataset)
      if modes.include?("create") || dhis2_dataset.nil?
        if dhis2_dataset
          Rails.logger.warn("not creating the dataset seem "\
            "to already exist : #{dataset.external_reference}")
          return
        end
        dhis2_dataset = create_dataset(dataset)
      end

      update(dhis2_dataset, dataset, modes)
      dataset.update(last_error: nil)
    rescue StandardError => e
      Rails.logger.error([e.class.name, e.message, e.backtrace.join("\n")].join("\n"))
      dataset.update(last_error: e.class.name + " " + e.message)
    ensure
      dataset.update(last_synched_at: DateTime.now)
    end
  end

  private

  attr_reader :legacy_project, :payment_rule

  def load_dhis2_dataset(dataset)
    return nil if dataset.external_reference.blank?

    dhis2_connection.data_sets.find(dataset.external_reference)
  rescue RestClient::NotFound
    nil
  end

  def dhis2_connection
    @dhis2_connection ||= payment_rule.project.dhis2_connection
  end

  def create_dataset(dataset)
    dataset_hash = Datasets::ToDhis2Datasets.new(dataset).call
    dhis2_status = dhis2_connection.data_sets.create(dataset_hash)
    Rails.logger.info dhis2_status.to_json
    dhis2_dataset = dhis2_connection.data_sets.find_by(name: dataset_hash[:name])
    dataset.external_reference = dhis2_dataset.id
    dataset.save!
    update(dhis2_dataset, dataset, MODES)
    dhis2_dataset
  end

  def update(dhis2_dataset, dataset, modes)
    diffs = Datasets::CalculateDesyncDatasets.new(legacy_project)
                                             .diff_actual_theorical(dhis2_dataset, dataset)
    add_orgunit_ids(dhis2_dataset, diffs.ou_diff.removed) if modes.include?(ADD_MISSING_OU)
    remove_orgunit_ids(dhis2_dataset, diffs.ou_diff.added) if modes.include?(REMOVE_EXTRA_OU)

    add_de_ids(dhis2_dataset, diffs.de_diff.removed) if modes.include?(ADD_MISSING_DE)
    remove_de_ids(dhis2_dataset, diffs.de_diff.added) if modes.include?(REMOVE_EXTRA_DE)

    dhis2_dataset.update
    dhis2_dataset
  end

  def add_orgunit_ids(dhis2_dataset, orgunit_ids)
    orgunits = dhis2_dataset.organisation_units
    orgunit_ids.each do |id_to_add|
      next if orgunits.include?("id" => id_to_add)

      orgunits.push("id" => id_to_add)
    end
  end

  def add_de_ids(dhis2_dataset, de_ids)
    if dhis2_dataset.data_set_elements
      add_de_ids_newer(dhis2_dataset, de_ids)
    else
      add_de_ids_legacy(dhis2_dataset, de_ids)
    end
  end

  def add_de_ids_newer(dhis2_dataset, de_ids)
    data_set_elements = dhis2_dataset.data_set_elements
    de_ids.each do |id_to_add|
      next if data_set_elements.any? { |de| de["data_element"] == { "id" => id_to_add } }
      
      dse = { "data_element" => { "id" => id_to_add }}
      dse["data_set"] = { "id" => dhis2_dataset.id } if dhis2_dataset.id
      data_set_elements.push(dse)
    end
  end

  def add_de_ids_legacy(dhis2_dataset, de_ids)
    data_elements = dhis2_dataset.data_elements
    de_ids.each do |id_to_add|
      next if data_elements.any? { |de| de["id"] == id_to_add  }

      data_elements.push("id" => id_to_add)
    end
  end

  def remove_orgunit_ids(dhis2_dataset, orgunit_ids)
    dhis2_dataset.organisation_units.delete_if { |ou| orgunit_ids.include?(ou["id"]) }
  end

  def remove_de_ids(dhis2_dataset, de_ids)
    if dhis2_dataset.data_set_elements
      dhis2_dataset.data_set_elements.delete_if { |de| de_ids.include?(de["data_element"]["id"]) }
    else
      dhis2_dataset.data_elements.delete_if { |de| de_ids.include?(de["id"]) }
    end
  end
end
