class CreateMissingDhis2ElementForActivityWorker < CreateDhis2ElementWorker
  def perform(project_id, payload)
    @project = Project.find(project_id)
    @activity = project.activities.find(payload.fetch("activity_id"))
    @state = project.states.find(payload.fetch("state_id"))
    @data_element = payload.fetch("data_element")
    create_data_element
  end

  private

  attr_reader :activity, :state, :data_element, :project

  def create_data_element
    element = create_and_find_in_dhis2
    activity.activity_states.create!(
      state:              state,
      name:               element.name,
      external_reference: element.id
    )
  end
end
