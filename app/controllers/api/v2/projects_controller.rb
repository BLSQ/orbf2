
# frozen_string_literal: true

module Api::V2
  class ProjectsController < BaseController
    def show
      render json: serializer_class.new(current_project_anchor).serialized_json
    end

    private

    def serializer_class
      ::V2::ProjectAnchorSerializer
    end
  end
end
