class AutocompleteController < PrivateController
  def organisation_unit_group
    autocomplete_for(:organisation_unit_groups)
  end

  def data_elements
    autocomplete_for_data_elements
  end

  private

  def autocomplete_for(item_name)
    if params.key?(:term)
      filter = "name:ilike:#{params[:term]}"
    elsif params.key?(:id)
      filter = "id:eq:#{params[:id]}"
    end

    dhis2 = current_user.project.dhis2_connection
    @items = dhis2.send(item_name)
                  .list(filter: filter,
                        fields: "id,name,displayName,organisationUnits~size~rename(orgunitscount)")
    render json: @items if @items.empty?
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

  def autocomplete_for_data_elements
    dhis2 = current_user.project.dhis2_connection
    dataelements = dhis2.data_elements
                        .list(fields: "id,displayName")
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
