class CreateDhis2ElementForFormulaMappingWorker < CreateDhis2ElementWorker
  def perform(project_id, payload)
    @project = Project.find(project_id)
    @activity = project.activities.find(payload["activity_id"]) if payload["activity_id"].present?
    @formula = Formula.find(payload.fetch("formula_id"))
    @data_element = payload.fetch("data_element")
    @kind = payload.fetch("kind")

    new_data_element = create_and_find_in_dhis2
    create_formula_mapping(new_data_element)
  end

  private

  attr_reader :activity, :formula, :kind

  def create_formula_mapping(new_data_element)
    formula.formula_mappings.create!(
      activity:           activity,
      kind:               kind,
      external_reference: new_data_element.id
    )
  end
end
