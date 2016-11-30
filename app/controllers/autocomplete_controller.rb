class AutocompleteController < PrivateController
  def organisation_unit_group
    autocomplete_for(:organisation_unit_groups)
  end

  private

  def autocomplete_for(item_name)
    term = params[:term]
    @items = current_user.project.dhis2_connection
                         .send(item_name)
                         .list(filter: "name:ilike:#{term}")
    @items = @items.map do |item|
      {
        value: item.display_name,
        id:    item.id
      }
    end
    render json: @items
  end
end
