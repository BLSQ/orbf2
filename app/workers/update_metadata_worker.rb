class UpdateMetadataWorker
  include Sidekiq::Worker

  sidekiq_options retry: 1

  def perform(project_id, update_params)
    project = Project.find(project_id)
    data_element = project.dhis2_connection.data_elements.find(update_params.fetch("dhis2_id"))
    data_element.name = update_params.fetch("name")
    data_element.short_name = update_params.fetch("short_name")
    data_element.code = update_params.fetch("code")
    data_element.update
  end
end
