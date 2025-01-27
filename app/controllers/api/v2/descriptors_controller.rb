# frozen_string_literal: true

module Api
    module V2
      class DescriptorsController < BaseController
        def show

            project = current_project_anchor.projects.where(id: params[:id]).fully_loaded.first
            descriptor = Descriptor::ProjectDescriptorFactory.new.project_descriptor(project)

            render json: descriptor.to_json
        end
      end
    end
end