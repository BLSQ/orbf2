# frozen_string_literal: true

module Activities
  class DataElementInfo
    attr_reader :id, :name, :kind
    def initialize(infos)
      @id = infos.fetch(:id).freeze
      @name = infos.fetch(:name).freeze
      @kind = infos.fetch(:kind).freeze
    end

    def self.from(kind:, element:)
      new(kind: kind, name: element.name, id: element.id)
    end
  end

  class ActivityStateAttributes
    attr_reader :project, :activity, :elements, :kind,
                :existing_element_ids, :selectable_element_ids

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
      elements_to_build
    end

    def elements_to_build
      if kind == ActivityState::KIND_DATA_ELEMENT_COC
        elements_to_build_data_element_cocs
      elsif kind == ActivityState::KIND_INDICATOR
        elements_to_build_indicators
      elsif kind == ActivityState::KIND_DATA_ELEMENT
        elements_to_build_data_elements
      else
        raise "unsupported kind : #{kind}"
      end
    end

    def elements_to_build_indicators
      data_compound = DataCompound.from(project)
      as_data_element_infos(
        selectable_element_ids.map { |element_id| new_data_element_info(data_compound.indicator(element_id)) }
      )
    end

    def elements_to_build_data_elements
      data_compound = DataCompound.from(project)
      as_data_element_infos(
        selectable_element_ids.map { |element_id| data_compound.data_element(element_id) }
      )
    end

    def as_data_element_infos(elements_to_build)
      elements_to_build.map { |element| new_data_element_info(element) }
    end

    def new_data_element_info(element)
      DataElementInfo.from(kind: kind, element: element)
    end

    def elements_to_build_data_element_cocs
      data_elements_with_coc(elements).each_with_object([]) do |de, results|
        de.category_combo["category_option_combos"].each do |coc|
          composite_id = de.id + "." + coc["id"]
          next if existing_element_ids.include?(composite_id)

          results << DataElementInfo.new(
            id:   composite_id,
            name: de.name + " - " + coc["name"],
            kind: kind
          )
        end
      end
    end

    def data_elements_with_coc(elements)
      project.dhis2_connection.data_elements.list(
        filter: "id:in:[" + elements.join(",") + "]",
        fields: "id,name,categoryCombo[id,name,categoryOptionCombos[id,name]]"
      )
    end
  end
end
