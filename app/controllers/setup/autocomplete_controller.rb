# frozen_string_literal: true

class Setup::AutocompleteController < PrivateController
  def organisation_unit_group
    if params.key?(:term)
      organisation_unit_group_by_term_on_sol
    elsif params.key?(:siblings)
      results = search_results(nil, "organisation_unit_groups", limit: 20_000)
      render_sol_items(results, nil)
    else
      render_sol_items([])
    end
  end

  DE_COC_FIELDS = %i[
    id
    display_name
    code
    category_combo__id
  ].freeze

  def data_elements_with_cocs
    if params[:id]
      if !params[:id].include?(".")
        expires_in 3.minutes
        results = find_results(params[:id], "data_elements")
        render_sol_items(results, params[:id])
      else
        datalement_id = params[:id].split(".")[0]
        coc_id = params[:id].split(".")[1]
        autocompleter = Autocomplete::Dhis2.new(current_project.project_anchor)
        data_elements = autocompleter.find(datalement_id, kind: "data_elements", fields: DE_COC_FIELDS)
        results = autocompleter.data_elements_with_category_combos(data_elements, limit_to_coc_with_id: coc_id)

        render_sol_items(results, params[:id])
      end
    elsif params[:term]
      term = params[:term]
      kind = "data_elements"
      autocompleter = Autocomplete::Dhis2.new(current_project.project_anchor)
      data_elements = autocompleter
                      .search(term, kind: kind, limit: 40, fields: DE_COC_FIELDS)
                      .sort_by(&:display_name)
      results = autocompleter.data_elements_with_category_combos(data_elements)

      render_sol_items(results.sort_by(&:display_name), params[:term])
    else
      results = search_results(nil, "data_elements", limit: 20_000)
      render_sol_items(results, nil)
    end
  end

  def data_elements
    if params[:id]
      expires_in 3.minutes
      results = find_results(params[:id], "data_elements")
      render_sol_items(results, params[:id])
    elsif params[:term]
      results = search_results(params[:term], "data_elements")
      render_sol_items(results, params[:term])
    else
      results = search_results(nil, "data_elements", limit: 20_000)
      render_sol_items(results, nil)
    end
  end

  def indicators
    data_compound = DataCompound.from(current_project)

    render_sol_items(data_compound.indicators)
  end

  def organisation_unit_group_sets
    pyramid = Pyramid.from(current_project)
    render_sol_items(pyramid.organisation_unit_group_sets)
  end

  def organisation_units
    if params[:id]
      results = find_results(params[:id], "organisation_units")
      render_sol_items(results, params[:id])
    else
      results = search_results(params[:term], "organisation_units")
      render_sol_items(results, params[:term])
    end
  end

  def category_combos
    results = search_results(params[:term], "category_combos")
    render_sol_items(results, params[:term])
  end

  def programs
    expires_in 5.minutes
    render_sol_items(current_project.dhis2_connection.programs.list(filter:"registration:eq:false"), params[:term].presence )
  end

  def sql_views
    expires_in 5.minutes
    sql_views = current_project.dhis2_connection.get("sqlViews")["sql_views"].map {|s| OpenStruct.new(s)}
    render_sol_items(sql_views, params[:term].presence )
  end

  private

  def search_results(term, kind, limit: 20)
    Autocomplete::Dhis2.new(current_project.project_anchor)
                       .search(term, kind: kind, limit: limit)
                       .sort_by(&:display_name)
  end

  def find_results(id, kind)
    Autocomplete::Dhis2.new(current_project.project_anchor)
                       .find(id, kind: kind)
  end

  def organisation_unit_group_by_term_on_sol
    pyr = Pyramid.from(current_project)

    org_unit_groups = pyr.org_unit_groups.map do |oug|
      ou_total = pyr.org_units_in_group(oug.id).size
      sample_ous = pyr.org_units_in_group(oug.id).to_a.sample(5).map(&:display_name)
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
    @items = items.compact.map do |item|
      {
        type:  "option",
        value: type.nil? ? item.id : item.display_name,
        id:    item.id,
        label: item.display_name
      }
    end
    render json: @items
  end
end
