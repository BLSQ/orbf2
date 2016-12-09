class AutocompleteController < PrivateController
  def organisation_unit_group
    if params.key?(:term) || params.key?(:id)
      organisation_unit_group_by_term_or_id
    elsif params.key?(:siblings)
      organisation_unit_group_by_used_or_sibling_id
    else
      render_sol_items([])
    end
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
  render_sol_items( current_user.project.entity_group.find_sibling_organisation_unit_groups)
end

def render_sol_items(items)
  @items = items.map do |item|
    {
      type:  "option",
      value: item.id,
      label: item.display_name
    }
  end
  render json: @items
end
