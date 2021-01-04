# frozen_string_literal: true

module Api
  module V2
    class DeCocsController < BaseController
      DE_COC_FIELDS = %i[
        id
        display_name
        code
        category_combo__id
      ].freeze

      def index
        results = []
        if params[:id]
          if !params[:id].include?(".")
            expires_in 3.minutes
            results = find_results(params[:id], "data_elements")
          else
            datalement_id = params[:id].split(".")[0]
            coc_id = params[:id].split(".")[1]
            autocompleter = Autocomplete::Dhis2.new(current_project_anchor)
            data_elements = autocompleter.find(datalement_id, kind: "data_elements", fields: DE_COC_FIELDS)
            results = autocompleter.data_elements_with_category_combos(data_elements, limit_to_coc_with_id: coc_id)
          end
        elsif params[:term]
          term = params[:term]
          kind = "data_elements"
          autocompleter = Autocomplete::Dhis2.new(current_project_anchor)
          data_elements = autocompleter
                          .search(term, kind: kind, limit: 40, fields: DE_COC_FIELDS)
                          .sort_by(&:display_name)
          results = autocompleter.data_elements_with_category_combos(data_elements)

          results = results.sort_by(&:display_name)
        else
          results = search_results(nil, "data_elements", limit: 20_000)
        end

        render json: serializer_class.new(results).serialized_json
      end

      def serializer_class
        ::V2::DeCocsSerializer
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
