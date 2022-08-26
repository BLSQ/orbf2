# frozen_string_literal: true

module Api
  module V2
    class InputsController < BaseController
      def create
        input = nil
        package = find_package

        State.transaction do
          input = create_input
          project = input.project
          package_state = package.package_states.create!({ state_id: input.id, package_id: package.id })
          package_state.reload
          package_state.package.reload
          project.reload
          input.save!
        end

        render json: serializer_class.new(input).serialized_json
      end

      private

      def find_package
        current_project_anchor.project.packages.find(params[:set_id])
      end

      def create_input
        current_project_anchor.project.states.create!(input_attributes)
      end

      def input_params
        params.require(:data)
              .permit(attributes: %i[
                        name
                        shortName
                      ])
      end

      def input_attributes
        att = input_params[:attributes]
        {
          name:       att[:name],
          short_name: att[:shortName]
        }
      end

      def serializer_class
        ::V2::StateSerializer
      end
    end
  end
end
