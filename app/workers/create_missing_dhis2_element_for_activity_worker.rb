
class CreateMissingDhis2ElementForActivityWorker
  include Sidekiq::Worker

  sidekiq_options retry: 1

  def perform(project_id, payload)
    @project = Project.find(project_id)

    @activity = project.activities.find(payload["activity_id"])
    @state = project.states.find(payload["state_id"])
    @data_element = payload["data_element"]
    create_data_element
  end

  private

  attr_reader :activity, :state, :data_element, :project

  def create_data_element
    dhis2 = project.dhis2_connection
    status = dhis2.data_elements.create(
      [
        {
          name:       data_element["name"],
          short_name: data_element["short_name"],
          code:       data_element["code"]
        }
      ]
    )
    element = dhis2.data_elements.find_by(code: data_element["code"])
    Rails.logger.info "data elements created #{status.to_json}, creating activity states"

    activity.activity_states.create!(
      state: state, 
      name: element.name, 
      external_reference: element.id
      )

    SynchroniseDegDsWorker.perform_async(project.project_anchor.id)
  end
end
