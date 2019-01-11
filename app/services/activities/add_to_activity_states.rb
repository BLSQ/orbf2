# frozen_string_literal: true

module Activities
  class AddToActivityStates
    attr_reader :project, :activity, :elements, :kind, :existing_element_ids, :selectable_element_ids

    def initialize(project:, activity:, elements:, kind:)
      @project = project
      @activity = activity
      @elements = elements || []
      @kind = kind
      @existing_element_ids = activity.activity_states
                                      .select { |as| as.kind == kind }
                                      .map(&:external_reference)
      @selectable_element_ids = @elements - existing_element_ids
    end

    def call
      elements_to_build.each do |element|
        @activity.activity_states.build(
          external_reference: element.id,
          name:               element.name,
          kind:               kind
        )
      end
    end

    def elements_to_build
      if kind == "data_element_coc"
        elements_to_build_data_element_cocs
      elsif kind == "indicator"
        elements_to_build_indicators
      elsif kind == "data_element"
        elements_to_build_data_elements
      else
        raise "unsupported kind : #{kind}"
      end
    end

    def elements_to_build_indicators
      data_compound = DataCompound.from(project)
      selectable_element_ids.map { |element_id| data_compound.indicator(element_id) }
    end

    def elements_to_build_data_elements
      data_compound = DataCompound.from(project)
      selectable_element_ids.map { |element_id| data_compound.data_element(element_id) }
    end

    def elements_to_build_data_element_cocs
      data_elements_with_coc = project.dhis2_connection.data_elements.list(
        filter: "id:in:[" + elements.join(",") + "]",
        fields: "id,name,categoryCombo[id,name,categoryOptionCombos[id,name]]"
      )
      data_elements_with_coc.each_with_object([]) do |de, results|
        de.category_combo["category_option_combos"].each do |coc|
          composite_id = de.id + "." + coc["id"]
          next if existing_element_ids.include?(composite_id)

          results << OpenStruct.new(
            id:   composite_id,
            name: de.name + " - " + coc["name"]
          )
        end
      end
    end
  end
end
