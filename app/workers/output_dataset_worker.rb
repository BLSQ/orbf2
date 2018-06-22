class OutputDatasetWorker
  include Sidekiq::Worker

  def perform(project_id)
    @legacy_project = Project.find(project_id)

    data_compound = legacy_project.project_anchor.nearest_data_compound_for(DateTime.now)
    legacy_pyramid = legacy_project.project_anchor.nearest_pyramid_for(DateTime.now)

    @pyramid = Orbf::RulesEngine::PyramidFactory.from_dhis2(
      org_units:          legacy_pyramid.org_units,
      org_unit_groups:    legacy_pyramid.org_unit_groups,
      org_unit_groupsets: legacy_pyramid.organisation_unit_group_sets
    )

    @project = MapProjectToOrbfProject.new(
      legacy_project,
      data_compound.indicators
    ).map

    Orbf::RulesEngine::Datasets::ComputeDatasets.new(
      project:      project,
      pyramid:      pyramid,
      group_ext_id: legacy_project.entity_group.external_reference
    ).call
  end

  private

  attr_reader :legacy_project, :project, :pyramid
end
