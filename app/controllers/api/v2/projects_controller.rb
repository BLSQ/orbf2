
# frozen_string_literal: true

module Api::V2
  class ProjectsController < BaseController
    def show
      render json: ProjectAnchorSerializer.new(current_project_anchor).serialized_json
    end
  end
end
