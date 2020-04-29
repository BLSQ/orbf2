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

  DE_COC_FIELDS = [
    :id,
    :display_name,
    :code,
    :category_combo__id
  ]

  def data_elements_with_cocs
    if params[:id]
      if (!params[:id].include?("."))
        expires_in 3.minutes
        results = find_results(params[:id], "data_elements")
        render_sol_items(results, params[:id])
      else
        datalement_id = params[:id].split(".")[0]
        coc_id = params[:id].split(".")[1]
        autocompleter = Autocomplete::Dhis2.new(current_project.project_anchor)
        data_elements = autocompleter.find(datalement_id, kind: "data_elements", fields: DE_COC_FIELDS)
        category_combo_by_id =autocompleter.find(data_elements.map(&:category_combo__id), kind: "category_combos", fields: [
                  :id,
                  :display_name,
                  :category_option_combos
                ]).index_by(&:id)
          results = data_elements.each_with_object([]) do |element, result|
            combo = category_combo_by_id[element.category_combo__id]

            if combo.display_name == "default" || combo.display_name == "(default)"
              result << element
            else
              combo.category_option_combos.each do |coc_hash|
                if coc_hash["id"] == coc_id
                  result << Struct.new(:id, :display_name).new(
                    [element.id, coc_hash["id"]].join("."),
                    [element.display_name, coc_hash["name"]].join(" - ")
                  )
                end
              end
            end
          end
          render_sol_items(results, params[:id])
      end
    elsif params[:term]

      term = params[:term]
      kind = "data_elements"
      autocompleter = Autocomplete::Dhis2.new(current_project.project_anchor)
      data_elements = autocompleter
                        .search(term, kind: kind, limit: 40, fields: DE_COC_FIELDS)
                        .sort_by(&:display_name)
      category_combo_ids = data_elements.map(&:category_combo__id).uniq
      category_combo_by_id = autocompleter
                               .find(category_combo_ids, kind: "category_combos", fields: [
                                         :id,
                                         :display_name,
                                         :category_option_combos
                                       ])
                               .index_by(&:id)

      results = data_elements.each_with_object([]) do |element, result|
        combo = category_combo_by_id[element.category_combo__id]

        # Avoid the default Category Combos (some DHIS use default, some use (default))
        # This is a guess
        if combo.display_name == "default" || combo.display_name == "(default)"
          result << element
        else
          combo.category_option_combos.each do |coc_hash|
            result << Struct.new(:id, :display_name).new(
              [element.id, coc_hash["id"]].join("."),
              [element.display_name, coc_hash["name"]].join(" - ")
            )
          end
        end
      end

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
