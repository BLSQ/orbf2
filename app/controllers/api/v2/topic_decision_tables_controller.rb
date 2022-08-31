module Api
  module V2
    class TopicDecisionTablesController < BaseController
      before_action :check_whodunnit!

      def update
        package = current_project_anchor.project.packages.find(params[:set_id])
        decision_table = package.activity_rule.decision_tables.find(params[:id])
        decision_table.update!(decision_table_attributes)
        options = {}
        render json: serializer_class.new(decision_table, options).serialized_json
      end

      def create
        package = current_project_anchor.project.packages.find(params[:set_id])
        decision_table = package.activity_rule.decision_tables.create!(decision_table_attributes)
        options = {}
        render json: serializer_class.new(decision_table, options).serialized_json
      end

      def destroy
        package = current_project_anchor.project.packages.find(params[:set_id])
        decision_table = package.activity_rule.decision_tables.find(params[:id])
        decision_table.destroy
        render json: { status: "done" }
      end

      private

      def serializer_class
        ::V2::DecisionTableSerializer
      end

      def decision_table_params
        params.require(:data)
              .permit(:type,
                      attributes: %i[
                        name
                        startPeriod
                        endPeriod
                        comment
                        sourceUrl
                        content
                      ])
      end

      def decision_table_attributes
        att = decision_table_params[:attributes]
        {
          name:         att[:name],
          start_period: att[:startPeriod],
          end_period:   att[:endPeriod],
          comment:      att[:comment],
          source_url:   att[:sourceUrl],
          content:      att[:content]
        }
      end
    end
  end
end
