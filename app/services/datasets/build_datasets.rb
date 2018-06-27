
module Datasets
  class BuildDatasets
    attr_reader :legacy_project

    def initialize(legacy_project)
      @legacy_project = legacy_project
    end

    def call
      dataset_infos = Orbf::RulesEngine::Datasets::ComputeDatasets.new(
        project:      project,
        pyramid:      pyramid,
        group_ext_id: legacy_project.entity_group.external_reference
      ).call

      dataset_infos.each do |ds|
        payment_rule = legacy_project.payment_rule_for_code(ds.payment_rule_code)
        dataset = payment_rule.dataset(ds.frequency)
        dataset ||= payment_rule.datasets.build(frequency: ds.frequency)
        dataset.dataset_info = ds
      end
    end

    private

    def data_compound
      @data_compound ||= legacy_project.project_anchor.nearest_data_compound_for(DateTime.now)
    end

    def legacy_pyramid
      @legacy_pyramid ||= legacy_project.project_anchor.nearest_pyramid_for(DateTime.now)
    end

    def pyramid
      @pyramid ||= Orbf::RulesEngine::PyramidFactory.from_dhis2(
        org_units:          legacy_pyramid.org_units,
        org_unit_groups:    legacy_pyramid.org_unit_groups,
        org_unit_groupsets: legacy_pyramid.organisation_unit_group_sets
      )
    end

    def project
      @project = MapProjectToOrbfProject.new(
        legacy_project,
        data_compound.indicators
      ).map
    end
  end
end
