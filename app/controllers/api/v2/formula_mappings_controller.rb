# frozen_string_literal: true

module Api::V2
  class FormulaMappingsController < BaseController
    before_action :check_whodunnit!, only: %i[create update delete]

    def create
      formula = current_formula

      formula_mapping = formula.formula_mappings.create!(formula_mapping_attributes.merge(kind: current_formula.rule.kind))
      # make stable id visible
      formula_mapping.reload
      render json: serializer_class.new(formula_mapping).serialized_json
    end

    def update
      formula_mapping = current_mapping

      formula_mapping.update!(formula_mapping_attributes)

      render json: serializer_class.new(formula_mapping).serialized_json
    end

    def index
      formula_mappings = current_project.packages.flat_map(&:rules).flat_map(&:formulas).flat_map(&:formula_mappings)
      render json: serializer_class.new(formula_mappings).serialized_json
    end

    def destroy
      formula_mapping = current_mapping
      formula_mapping.destroy!
    end

    private

    def current_mapping
      formula_mapping = FormulaMapping.find(params[:id])
      raise ActiveRecord::RecordNotFound if formula_mapping.project_id != current_project.id

      formula_mapping
    end

    def current_formula
      formula = Formula.find(formula_mapping_attributes[:formula_id])
      raise ActiveRecord::RecordNotFound if formula.project_id != current_project.id

      formula
    end

    def current_project
      current_project_anchor.project
    end

    def serializer_class
      ::V2::FormulaMappingSerializer
    end

    def formula_mapping_params
      params.require(:data)
            .permit(:type,
                    attributes: %i[
                      topicId
                      formulaId
                      externalReference
                    ])
    end

    def formula_mapping_attributes
      att = formula_mapping_params[:attributes]
      {
        formula_id:         att[:formulaId],
        activity_id:        att[:topicId],
        external_reference: att[:externalReference]
      }
    end
  end
end
