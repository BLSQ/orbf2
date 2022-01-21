# frozen_string_literal: true

module Api
  module V2
    class OrgUnitsController < BaseController
      MAX_LIMIT = 9999
      def index
        results = if params[:id]
                    find_results(params[:id], "organisation_units")
                  elsif params[:term]
                    search_results(params[:term], "organisation_units")
                  else
                    # "" will evaluate to '%%' so will return everything
                    search_results("", "organisation_units", limit: MAX_LIMIT)
                  end

        render json: serializer_class.new(results).serialized_json
      end

      private

      def serializer_class
        ::V2::OrgUnitSerializer
      end

      def find_results(id, kind)
        Autocomplete::Dhis2.new(current_project_anchor)
                           .find(id, kind: kind)
      end

      def search_results(term, kind, limit: 20)
        Autocomplete::Dhis2.new(current_project_anchor)
                           .search(term, kind: kind, limit: limit)
                           .sort_by(&:display_name)
      end
    end
  end
end
