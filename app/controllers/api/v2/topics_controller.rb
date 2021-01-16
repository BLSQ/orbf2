# frozen_string_literal: true

module Api::V2
  class TopicsController < BaseController
    before_action :check_whodunnit!, only: %i[create update delete]

    def create
      topic = current_project.activities.create!(topic_attributes)
      # make stable id visible
      topic.reload

      synchronize_relationships(topic)

      render json: serializer_class.new(topic).serialized_json
    end

    def update
      topic = current_project.activities.find(params[:id])
      topic.update!(topic_attributes)

      synchronize_relationships(topic)

      render json: serializer_class.new(topic).serialized_json
    end

    def index
      topics = current_project.activities
      render json: serializer_class.new(topics).serialized_json
    end

    private

    def synchronize_relationships(topic)
      # handle optional set relationships
      return unless params[:data]
      return unless params[:data][:relationships]
      return unless params[:data][:relationships][:sets]

      package_ids = params[:data][:relationships][:sets].map { |hesabuset| hesabuset["id"] }
      
      current_project.packages.each do |package|
        activity_package = package.activity_packages.where(activity_id: topic.id).first

        if package_ids.include?(package.id.to_s) && activity_package.nil?
          # puts "adding #{topic} to package #{package}"
           package.activities << topic 
        end
        if activity_package && !package_ids.include?(package.id)
          #puts "removing #{topic} from package #{package}"
          activity_package.destroy 
        end
      end
    end

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
