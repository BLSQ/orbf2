# frozen_string_literal: true

class Setup::DiagnoseController < PrivateController
  helper_method :project, :contracted_entities, :minimum_packages, :pyramid
  attr_accessor :minimum_packages, :pyramid
  attr_reader :contracted_entities

  def index
    @minimum_packages = params[:minimum_packages] ? params[:minimum_packages].to_i : 1

    @contracted_entities = legacy_pyramid.org_units_in_all_groups([legacy_project.entity_group.external_reference])
                                         .map do |legacy_org_unit|
      org_unit = pyramid.org_unit(legacy_org_unit.id)
      matching_packages = project.packages
                                 .each_with_object({}) do |package, hash|
        hash[package] = Orbf::RulesEngine::OrgunitsResolver.new(package, pyramid, org_unit).call
      end

      OpenStruct.new(
        org_unit:          org_unit,
        full_name:     org_unit.parent_ext_ids.map do |ext_id|
          pyramid.org_unit(ext_id).name
        end.join(" > "),
        matching_packages: matching_packages,
        packages:          project.packages.map do |package|
          OpenStruct.new(
            code:      package.code,
            match:     !matching_packages[package].empty?,
            org_units: matching_packages[package]
          )
        end
      )
    end
  end

  private

  def legacy_project
    current_project(project_scope: :fully_loaded)
  end

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
    @project ||= MapProjectToOrbfProject.new(
      current_project,
      data_compound.indicators
    ).map
  end
end
