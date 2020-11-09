# frozen_string_literal: true

module Api::V2
  class TopicsController < BaseController
    def create
      topic = current_project.activities.create!(topic_attributes)
      # make stable id visible
      topic.reload
      render json: serializer_class.new(topic).serialized_json
    end


    def update
      topic = current_project.activities.find(params[:id])
      topic.update_attributes!(topic_attributes)

      render json: serializer_class.new(topic).serialized_json
    end

    def index
      topics = current_project.activities
      render json: serializer_class.new(topics).serialized_json
    end

    private

    def current_project
      current_project_anchor.project
    end

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
      att = topic_params[:attributes]
      {
        name:       att[:name],
        short_name: att[:shortName],
        code:       att[:code]
      }
    end
  end
end
