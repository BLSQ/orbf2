class AutocompleteController < PrivateController
  def organisation_unit_group
    organisation_unit_group_by_term_or_id if params.key?(:term) || params.key?(:id)
    organisation_unit_group_by_used_or_sibling_id if params.key?(:sibling_id)
  end

  def data_elements
    dhis2 = current_user.project.dhis2_connection
    dataelements = dhis2.data_elements
                        .list(fields: "id,displayName", page_size: 20_000)
    render_sol_items(dataelements)
  end
end

private

def organisation_unit_group_by_term_or_id
  if params.key?(:term)
    filter = "name:ilike:#{params[:term]}"
  elsif params.key?(:id)
    filter = "id:eq:#{params[:id]}"
  end

  dhis2 = current_user.project.dhis2_connection
  @items = dhis2.organisation_unit_groups
                .list(filter: filter,
                      fields: "id,name,displayName,organisationUnits~size~rename(orgunitscount)")
  render json: @items && return if @items.empty?
  total = dhis2.organisation_units.list.pager.total

  @items = @items.map do |item|
    organisation_units = dhis2.organisation_units
                              .list(
                                filter:    "organisationUnitGroups.id:eq:#{item.id}",
                                page_size: 5
                              ).map { |orgunit| { name: orgunit.display_name } }
    {
      value:                    item.display_name,
      id:                       item.id,
      organisation_units_count: item.orgunitscount.to_s,
      organisation_units:       organisation_units,
      organisation_units_total: total
    }
  end
  render json: @items
end

def organisation_unit_group_by_used_or_sibling_id
  dhis2 = current_user.project.dhis2_connection
  units = dhis2.organisation_units.list(page_size: 50_000, fields: "id,name,organisationUnitGroups")
  main_group_id = current_user.project.entity_group.external_reference
  group_ids = units.select { |unit| unit.organisation_unit_groups.any? { |g| g["id"] == main_group_id } }
                   .map(&:organisation_unit_groups)
                   .flatten.map { |g| g["id"] }.uniq

  group_ids -= [main_group_id]
  groups = dhis2.organisation_unit_groups.find(group_ids).uniq
  render_sol_items(groups)
end

def render_sol_items(items)
  items = items.map do |item|
    {
      type:  "option",
      value: item.id,
      label: item.display_name
    }
  end
  render json: items
end
