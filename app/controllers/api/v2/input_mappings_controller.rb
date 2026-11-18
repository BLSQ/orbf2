# frozen_string_literal: true

module Api::V2
  class InputMappingsController < BaseController
    before_action :check_whodunnit!, only: %i[create create_data_element update delete]

    # creates the data element in dhis2 then maps it to the state of the topic
    #   data: { attributes: { code: <state code>,
    #           dataElement: { name, shortName, code, valueType, aggregationType } } }
    def create_data_element
      activity = current_activity
      state_code = params.dig(:data, :attributes, :code)
      state = activity.project.state(state_code)
      refusal = mapping_refusal(activity, state, state_code)
      return bad_request(refusal) if refusal

      activity_state = map_new_data_element(activity, state, data_element_params)
      SynchroniseDegDsWorker.perform_async(current_project.project_anchor.id)
      render_activity_state(activity_state)
    rescue DataElementCreator::Error => e
      bad_request(e.message)
    end

    def create
      activity = current_activity
      state_code = input_params[:attributes][:code]
      state = if state_code
                # ease client work allowing to pass the state code
                activity.project.state(state_code)
              else
                # find by relationships ?
              end
      activity_state = activity.activity_states.create!(input_attributes.merge(state_id: state.id))
      # make stable id visible
      activity_state.reload
      SynchroniseDegDsWorker.perform_async(current_project.project_anchor.id)
      render_activity_state(activity_state)
    end

    def index
      inputs = current_activity.activity_states
      render json: serializer_class.new(inputs, include: default_relationships).serializable_hash.to_json
    end

    def update
      activity_state = current_activity.activity_states.find(params[:id])
      state_code = input_params[:attributes][:code]
      state = if state_code
                # ease client work allowing to pass the state code
                activity_state.activity.project.state(state_code)
              else
                activity_state.state
              end
      activity_state.update!(input_attributes.merge(state_id: state.id))
      SynchroniseDegDsWorker.perform_async(current_project.project_anchor.id)

      render_activity_state(activity_state)
    end

    def destroy
      activity_state = current_activity.activity_states.find(params[:id])
      activity_state.destroy!
      render_activity_state(activity_state)
    end

    private

    def render_activity_state(activity_state)
      render(
        json: serializer_class.new(
          activity_state,
          include: default_relationships
        ).serializable_hash.to_json
      )
    end

    def default_relationships
      %i[input external_ref]
    end

    def current_project
      current_project_anchor.project
    end

    def current_activity
      current_project.activities.find(params[:topic_id])
    end

    def serializer_class
      ::V2::ActivityStateSerializer
    end

    def input_params
      params.require(:data)
            .permit(:type,
                    attributes: %i[
                      code
                      formula
                      name
                      origin
                      kind
                      externalReference
                    ])
    end

    # checked before creating the data element: it would stay unmapped in dhis2
    def mapping_refusal(activity, state, state_code)
      return "unknown state #{state_code}" unless state

      already_mapped = activity.activity_states.exists?(state_id: state.id)
      "#{state.code} is already mapped for #{activity.code}" if already_mapped
    end

    def map_new_data_element(activity, state, element)
      element_id = DataElementCreator.new(activity.project).call(element)
      activity.activity_states.create!(
        state:              state,
        name:               element[:name],
        kind:               ActivityState::KIND_DATA_ELEMENT,
        origin:             ActivityState::ORIGIN_DATAVALUESETS,
        external_reference: element_id
      ).reload
    end

    def input_attributes
      att = input_params[:attributes]
      {
        formula:            att[:formula].presence,
        name:               att[:name].presence,
        origin:             att[:origin].presence,
        kind:               att[:kind].presence,
        external_reference: att[:externalReference].presence
      }
    end
  end
end
