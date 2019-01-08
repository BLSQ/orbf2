# frozen_string_literal: true

module Descriptor
  class PackageDescription
    attr_reader :package
    def initialize(package)
      @package = package
    end

    def data_set_ids
      package.package_states.map(&:ds_external_reference).compact
    end

    def data_element_group_ids
      package.package_states.map(&:deg_external_reference).compact
    end

    def main_org_unit_group_ids
      package.main_entity_groups.map(&:organisation_unit_group_ext_ref).compact
    end

    def target_org_unit_group_ids
      package.target_entity_groups.map(&:organisation_unit_group_ext_ref).compact
    end

    def activity_descriptors
      ActivityDescription.new(package).activity_descriptors
    end
  end
end
