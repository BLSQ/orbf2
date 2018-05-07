
class CreateDhis2ElementWorker
  include Sidekiq::Worker

  sidekiq_options retry: 1

  attr_reader :data_element, :project

  def create_and_find_in_dhis2
    dhis2 = project.dhis2_connection
    status = dhis2.data_elements.create(to_data_element_creation_payload)
    Rails.logger.info "data elements created #{status.to_json}, creating activity states"
    raise "can't create data element #{status.to_json} vs #{data_element.to_json}" unless status.success?
    dhis2.data_elements.find_by(code: data_element["code"])
  end

  # the gem wants symbols not strings
  def to_data_element_creation_payload
    {
      name:       data_element.fetch("name"),
      short_name: data_element.fetch("short_name"),
      code:       data_element.fetch("code")
    }
  end
end
