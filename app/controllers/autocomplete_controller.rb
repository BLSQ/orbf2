class AutocompleteController < PrivateController
  def organisation_unit_group
    autocomplete_for(:organisation_unit_groups)
  end

  private

  def autocomplete_for(item_name)
    term = params[:term]
    dhis2 = current_user.project.dhis2_connection
    total = dhis2.organisation_units.list.pager.total
    @items = dhis2.send(item_name)
                  .list(filter: "name:ilike:#{term}",
                        fields: "id,name,displayName,organisationUnits~size~rename(orgunitscount)")
    @items = @items.map do |item|
      organisation_units = dhis2.organisation_units
                                .list(filter: "organisationUnitGroups.id:eq:#{item.id}",page_size:5).map { |orgunit| { name: orgunit.display_name } }
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
end
