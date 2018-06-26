module Datasets
  class CalculateDesyncDatasets
    Diff = Struct.new(:status, :added, :removed)
    Diffs = Struct.new(:de_diff, :ou_diff) do
      def status
        de_diff.status && ou_diff.status
      end
    end

    attr_reader :legacy_project
    def initialize(legacy_project)
      @legacy_project = legacy_project
    end

    def call
      legacy_project.payment_rules
                    .flat_map(&:datasets)
                    .each do |payment_rule_dataset|
        dhis2_dataset = load_dhis2_dataset(payment_rule_dataset.external_reference)
        payment_rule_dataset.dhis2_dataset = dhis2_dataset
        diff_actual_theorical(dhis2_dataset, payment_rule_dataset)
      end
    end

    def load_dhis2_dataset(ref)
      return nil unless ref
      legacy_project.dhis2_connection
                    .data_sets
                    .find(ref)
    rescue RestClient::NotFound
      nil
    end

    def diff_actual_theorical(dhis2_dataset, payment_rule_dataset)
      current_ou_ids = dhis2_dataset ? dhis2_dataset.organisation_units.map { |o| o["id"] } : []
      current_de_ids = dhis2_dataset ? dhis2_dataset.data_set_elements.map { |o| o["data_element"]["id"] } : []

      dataset_info = payment_rule_dataset.dataset_info

      payment_rule_dataset.diff = Diffs.new(
        diff(current_de_ids, dataset_info.data_elements),
        diff(current_ou_ids, dataset_info.orgunits.map(&:ext_id))
      )
    end

    def diff(current_values, new_values)
      Diff.new(
        current_values.sort == new_values.sort,
        current_values - new_values,
        new_values - current_values
      )
    end
  end
end
