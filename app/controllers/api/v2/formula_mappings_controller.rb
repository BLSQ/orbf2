# frozen_string_literal: true

module Api::V2
  class FormulaMappingsController < BaseController
    before_action :check_whodunnit!, only: %i[create create_data_element update delete]

    # creates the data element in dhis2 then maps the formula (of the topic) to it
    #   data: { attributes: { formulaId, topicId (activity formulas),
    #           dataElement: { name, shortName, code, valueType, aggregationType } } }
    def create_data_element
      formula = current_formula
      activity = mapped_activity
      refusal = mapping_refusal(formula, activity)
      return bad_request(refusal) if refusal

      formula_mapping = map_new_data_element(formula, activity, data_element_params)
      OutputDatasetWorker.trigger_sync_for_project(current_project)
      render json: serializer_class.new(formula_mapping).serializable_hash.to_json
    rescue DataElementCreator::Error => e
      bad_request(e.message)
    end

    def create
      formula = current_formula

      formula_mapping = formula.formula_mappings.create!(formula_mapping_attributes.merge(kind: current_formula.rule.kind))
      # make stable id visible
      formula_mapping.reload

      OutputDatasetWorker.trigger_sync_for_project(current_project)

      render json: serializer_class.new(formula_mapping).serializable_hash.to_json
    end

    def update
      formula_mapping = current_mapping

      formula_mapping.update!(formula_mapping_attributes)

      OutputDatasetWorker.trigger_sync_for_project(current_project)
      
      render json: serializer_class.new(formula_mapping).serializable_hash.to_json
    end

    def index
      formula_mappings = current_project.packages.flat_map(&:rules).flat_map(&:formulas).flat_map(&:formula_mappings)
      render json: serializer_class.new(formula_mappings).serializable_hash.to_json
    end

    def destroy
      formula_mapping = current_mapping
      formula_mapping.destroy!
      render json: serializer_class.new(formula_mapping).serializable_hash.to_json
    end

    private

    def mapped_activity
      activity_id = formula_mapping_attributes[:activity_id]
      current_project.activities.find(activity_id) if activity_id.present?
    end

    # checked before creating the data element: it would stay unmapped in dhis2
    def mapping_refusal(formula, activity)
      return unless formula.formula_mappings.exists?(activity_id: activity&.id)

      "#{formula.code} is already mapped#{" for #{activity.code}" if activity}"
    end

    def map_new_data_element(formula, activity, element)
      element_id = DataElementCreator.new(current_project).call(element)
      formula.formula_mappings.create!(
        activity:           activity,
        kind:               formula.rule.kind,
        external_reference: element_id
      ).reload
    end

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
