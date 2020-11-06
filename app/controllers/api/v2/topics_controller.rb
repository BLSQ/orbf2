# frozen_string_literal: true

module Api::V2
  class TopicsController < BaseController
    def create

      item = current_project_anchor.project.activities.create!(topic_attributes)

      item.reload
      render json: serializer_class.new(item).serialized_json
    end

    private

    def serializer_class
      ::V2::ActivitySerializer
    end

    def topic_params
      params.require(:data)
            .permit(:type,
                    attributes: %i[
                      code
                      name
                      shortName
                    ])
    end

    def topic_attributes
      {
        name:       topic_params[:attributes][:name],
        short_name: topic_params[:attributes][:shortName],
        code:       topic_params[:attributes][:code]
      }
    end
  end
end
