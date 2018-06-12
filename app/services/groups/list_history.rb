
class Groups::ListHistory
  def initialize(group_params)
    @group_params = group_params
  end

  def call
    months = group_params.compared_months + [group_params.reference_period]
    pyramids = fetch_pyramids(group_params.project, months)

    selected_orgunits = fetch_selected_orgunits(
      group_params.project,
      pyramids,
      group_params.selected_orgunit_ids,
      group_params.excluded_orgunit_ids
    )

    orgunits_history(selected_orgunits, pyramids, group_params.groupset_id).flatten(1)
  end

  private

  attr_reader :group_params

  def fetch_selected_orgunits(project, pyramids, selected_regions, rejected_districts = [])
    orgunits = Set.new
    pyramids.each_value do |pyramid|
      contracted = pyramid.org_units_in_group(project.entity_group.external_reference)
      orgunits.merge(contracted)
    end

    orgunits = orgunits.to_a.index_by(&:id).values

    selected_orgunits = orgunits.select do |ou|
      selected_regions.any? { |selected_region| ou.path.include?(selected_region) } &&
        rejected_districts.none? { |rejected_district| ou.path.include?(rejected_district) }
    end
    selected_orgunits.sort_by(&:path)
  end

  def fetch_pyramids(project, months)
    months.each_with_object({}) do |month_period, hash|
      pyramid = project.project_anchor.nearest_pyramid_for(month_period.end_date)
      hash[month_period] = pyramid
    end
  end

  def orgunits_history(selected_orgunits, pyramids, subcontract_groupset_id)
    selected_orgunits.map do |selected_orgunit|
      pyramids.map do |period, pyramid|
        map_to_history(selected_orgunit, period, subcontract_groupset_id, pyramid)
      end
    end
  end

  def map_to_history(selected_orgunit, period, subcontract_groupset_id, pyramid)
    orgunit = pyramid.org_unit(selected_orgunit.id)
    unless orgunit
      return {
        id:     selected_orgunit.id,
        name:   name(selected_orgunit),
        period: period
      }
    end
    orgunit_group_ids = orgunit.organisation_unit_groups.map { |g| g["id"] }.sort
    orgunit_groups = pyramid.org_unit_groups(orgunit_group_ids.sort)
    parents = pyramid.org_unit_parents(orgunit.id)[0..-2]

    if subcontract_groupset_id
      subcontracted_ous = pyramid.org_units_in_same_group(orgunit, subcontract_groupset_id)
      groupset_group_ids = pyramid.org_unit_group_set(subcontract_groupset_id)
                                  .organisation_unit_groups
                                  .map { |e| e["id"] }
      groupet_org_unit_group_ids = orgunit.organisation_unit_groups
                                          .map { |e| e["id"] }
      contract_group_ids = (groupset_group_ids & groupet_org_unit_group_ids).sort
      contract_groups = pyramid.org_unit_groups(contract_group_ids)
    else
      contract_groups = []
      subcontracted_ous = []
    end
    {
      id:                       orgunit.id,
      name:                     name(orgunit),
      period:                   period,
      ancestors:                parents.map { |parent| to_orgunit(parent) },
      organisation_unit_groups: orgunit_groups.compact
                                              .sort_by(&:name)
                                              .map { |g| to_group(g, pyramid) },
      contract_group:           contract_groups.map { |g| to_group(g, pyramid) },
      contract_members:         subcontracted_ous.map { |ou| to_orgunit(ou) }
    }
  end

  def to_orgunit(o)
    { id: o.id, name: name(o), level: o.path.split("/").length - 1 }
  end

  def name(dhis_resource)
    dhis_resource.name || dhis_resource.display_name
  end

  def to_group(g, pyramid)
    result = { id: g.id, name: g.name }
    if g.organisation_unit_group_set
      group_set = pyramid.org_unit_group_set(g.organisation_unit_group_set["id"])
      if group_set
        result[:organisation_unit_group_set] = { id: group_set.id, name: name(group_set) }
      end
    end
    result
  end
end
