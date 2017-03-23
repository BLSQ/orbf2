class Setup::AutocompleteController < PrivateController
  def organisation_unit_group
    if params.key?(:term)
      organisation_unit_group_by_term_on_sol
    elsif params.key?(:siblings)
      organisation_unit_group_by_used_or_sibling_id
    else
      render_sol_items([])
    end
  end

  def data_elements
    data_compound = DataCompound.from(current_project)
    if params[:id]
      render_sol_items([data_compound.data_element(params[:id])], params[:id])
    else
      render_sol_items(filter_ilike(data_compound.data_elements, params[:term]), params[:term])
    end
  end

  def indicators
    data_compound = DataCompound.from(current_project)

    render_sol_items(data_compound.indicators)
  end
end

private

def filter_ilike(elements, name)
  return elements if name.nil?

  search_name = transliterate(name)
  selected = elements.select do |element|
    name.length < 4 ? transliterate(element.display_name).starts_with?(search_name) : transliterate(element.display_name).include?(search_name)
  end
  selected.first(20)
end

def transliterate(name)
  ActiveSupport::Inflector.transliterate(name).downcase
end

def organisation_unit_group_by_term_on_sol
  pyr = Pyramid.from(current_project)

  org_unit_groups = pyr.org_unit_groups.map do |oug|
    ou_total = pyr.org_units_in_group(oug.id).size
    sample_ous = pyr.org_units_in_group(oug.id).to_a.shuffle.slice(0, 5).map(&:display_name)
    {
      type:  "option",
      value: oug.id,
      label: "#{oug.display_name} (#{ou_total}/#{pyr.org_units.size}) : #{sample_ous.join(', ')},..."
    }
  end

  @items = org_unit_groups
  render json: org_unit_groups
end

def organisation_unit_group_by_used_or_sibling_id
  pyr = Pyramid.from(current_project)
  sibling_id = current_project.entity_group.external_reference
  render_sol_items(pyr.find_sibling_organisation_unit_groups(sibling_id))
end

def render_sol_items(items, type = nil)
  @items = items.reject(&:nil?).map do |item|
    {
      type:  "option",
      value: type.nil? ? item.id : item.display_name,
      id: item.id,
      label: item.display_name
    }
  end
  render json: @items
end
