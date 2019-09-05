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
      facts = {}
      matching_packages = project.packages
                                 .each_with_object({}) do |package, hash|
        hash[package] = Orbf::RulesEngine::OrgunitsResolver.new(package, pyramid, org_unit).call
        decision_table = package.rules.flat_map(&:decision_tables).compact
        org_unit_facts = Orbf::RulesEngine::OrgunitFacts.new(org_unit, pyramid).to_facts

        facts = package.all_activities_codes
                       .each_with_object([]) do |activity_code, array|
          decision_table.each do |decision_table|
            input_facts = org_unit_facts
                          .merge("activity_code" => activity_code)
            output_facts = decision_table.find(input_facts)
            next unless output_facts && output_facts["unit_amount"]
            puts " #{package.code} #{org_unit.name}"
            puts "#{(decision_table.headers(:in) - input_facts.keys)} : #{output_facts}"
            array.push(output_facts)
          end
        end
      end

      OpenStruct.new(
        org_unit:          org_unit,
        full_name:         org_unit.parent_ext_ids.map do |ext_id|
          pyramid.org_unit(ext_id).name
        end.join(" > "),
        matching_packages: matching_packages,
        facts:             facts,
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

  def show
    @possible_values_groupset_code = pyramid.org_unit_groupsets.each_with_object({}).each do |groupset, map|
      map["groupset_code_"+groupset.code] = groupset.group_ext_ids.map { |gid| pyramid.groups(gid).first.code }.sort
    end

    decision_tables = []
    project.packages.each do |package|
      package.rules.each do |rule|
        rule.decision_tables.each do |decision_table|
          lines = decision_table.rules.map { |line| line.instance_variable_get(:@row) }

          used_values = decision_table.headers(:in).each_with_object({}) do |in_header, vals|
            vals[in_header] = lines.map { |l| l["in:" + in_header] }.uniq
          end

          decision_tables.push(OpenStruct.new(package: package, rule: rule, decision_table: decision_table, used_values: used_values || {}))
        end
      end
    end
    @decision_tables = decision_tables
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
      data_compound
    ).map
  end
end
