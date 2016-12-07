class AutocompleteController < PrivateController
  def organisation_unit_group
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

  def data_elements
    dhis2 = current_user.project.dhis2_connection
    dataelements = dhis2.data_elements
                        .list(fields: "id,displayName", page_size: 20_000)
                        .map do |dataelement|
                          {
                            type:  "option",
                            value: dataelement.id,
                            label: dataelement.display_name
                          }
                        end
    render json: dataelements
  end
end
