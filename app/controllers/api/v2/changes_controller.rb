# frozen_string_literal: true

module Api
  module V2
    class ChangesController < BaseController
      def index
        changes = project.project_anchor.program.versions.order("id DESC").limit(100)

        hesabu_objects = {}
        # avoid select n+1
        changes.group_by(&:item_type).each do |item_type, related_changes|
          instance_eval(item_type).all.where(id:related_changes.map(&:item_id)).each do |hesabu_model_instance|
            hesabu_objects["#{item_type}-#{hesabu_model_instance.id}"] = hesabu_model_instance
          end
        end
        
        options = { params: { hesabu_objects: hesabu_objects }}

        render json: serializer_class.new(changes, options).serialized_json
      end

      private

      def project
        current_project_anchor.project
      end

      def serializer_class
        ::V2::ChangeSerializer
      end
    end
  end
end
