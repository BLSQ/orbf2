
class Pyramid
  def initialize(org_units, org_unit_groups, org_unit_group_sets)
    @org_unit_groups_by_id = org_unit_groups.index_by(&:id)
    @org_units_by_id = org_units.index_by(&:id)
    @org_unit_group_sets_by_id = org_unit_group_sets.index_by(&:id)

    org_units_by_group = {}
    org_units.each do |ou|
      next unless ou.organisation_unit_groups
      ou.organisation_unit_groups.each do |group|
        org_units_by_group[group["id"]] ||= Set.new
        org_units_by_group[group["id"]].add(ou)
      end
    end
    @org_units_by_group = org_units_by_group
  end

  def self.from(project)
    pyramid = project.project_anchor.nearest_pyramid_for(Time.now.utc.end_of_month)

    return pyramid if pyramid
    dhis2 = project.dhis2_connection
    org_unit_groups = dhis2.organisation_unit_groups
                           .list(fields: "id,displayName", page_size: 20_000)
    org_units = dhis2.organisation_units
                     .list(fields: "id,displayName,path,organisationUnitGroups", page_size: 50_000)
    org_unit_group_sets = dhis2.organisation_unit_group_sets
                               .list(fields: "id,displayName", page_size: 20_000)

    Pyramid.new(org_units, org_unit_groups, org_unit_group_sets)
  end

  def org_unit(id)
    @org_units_by_id[id]
  end

  def org_units(ids = nil)
    ids ? ids.map { |id| @org_units_by_id[id] } : @org_units_by_id.values
  end

  def org_unit_groups(ids = nil)
    ids ? ids.map { |id| @org_unit_groups_by_id[id] } : @org_unit_groups_by_id.values
  end

  def org_units_in_group(group_id)
    @org_units_by_group[group_id] || Set.new
  end

  def organisation_unit_group_sets
    @org_unit_group_sets_by_id.values
  end

  def org_unit_group_set(group_set_id)
    @org_unit_group_sets_by_id[group_set_id]
  end

  def org_unit_groups_of(org_unit)
    org_unit_groups(org_unit.organisation_unit_groups.map { |e| e["id"] })
  end

  def org_units_in_same_group(org_unit, group_set_id)
    groupset_group_ids = org_unit_group_set(group_set_id).organisation_unit_groups.map { |e| e["id"] }
    org_unit_group_ids = org_unit.organisation_unit_groups.map { |e| e["id"] }
    group_id = (groupset_group_ids & org_unit_group_ids).first

    orgs = org_units_in_group(group_id)
    puts "warn #org_units_in_same_group(#{org_unit.id} - #{org_unit.display_name}, #{group_set_id}) : large number of org units in the same group #{orgs.size} " if orgs.size > 100
    orgs
  end

  def org_units_in_all_groups(group_ids)
    entities_in_groups = group_ids.map { |group_id| org_units_in_group(group_id) }
    entities_in_groups.reduce(&:intersection)
  end

  def org_unit_parents(org_unit_id)
    ou = org_unit(org_unit_id)
    return [ou] unless ou.path
    ou.path.split("/").reject(&:empty?).map { |parent_id| org_unit(parent_id) }
  end

  def find_sibling_organisation_unit_groups(group_id)
    units = org_units

    sibling_group_ids = units.reject { |unit| unit.organisation_unit_groups.nil? }
                             .select { |unit| unit.organisation_unit_groups.any? { |g| g["id"] == group_id } }
                             .map(&:organisation_unit_groups)
                             .flatten
                             .map { |g| g["id"] }
                             .uniq
    sibling_group_ids -= [group_id]
    sibling_group_ids.map { |group_id| @org_unit_groups_by_id[group_id] }
  end
end
