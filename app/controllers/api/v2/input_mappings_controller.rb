# frozen_string_literal: true

module Api::V2
  class InputMappingsController < BaseController
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
      render json: serializer_class.new(activity_state, include: default_relationships).serialized_json
    end

    def index
      inputs = current_activity.activity_states
      render json: serializer_class.new(inputs, include: default_relationships).serialized_json
    end

    private

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
