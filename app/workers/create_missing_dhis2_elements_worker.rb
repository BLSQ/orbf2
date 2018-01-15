
class CreateMissingDhis2ElementsWorker
  include Sidekiq::Worker

  def perform(project_anchor_id)
    now = Time.now.utc

    project_anchor = ProjectAnchor.find(project_anchor_id)

    project = project_anchor.latest_draft || project_anchor.projects.for_date(now)

    dhis2 = project.dhis2_connection
    elements = {}
    project.missing_activity_states.each do |activity, states|
      states.map do |state|
        de = {
          code:         "#{state.code}-#{activity.stable_id}",
          short_name:   "#{state.name}-#{activity.name}"[0..49],
          name:         "#{state.name} - #{activity.name}",
          display_name: "#{state.name} - #{activity.name}"
        }
        elements[[activity, state]] = de
        de
      end
    end

    Rails.logger.info "About to create missing data elements"
    Rails.logger.info JSON.pretty_generate(elements.values)
    status = dhis2.data_elements.create(elements.values.flatten)
    Rails.logger.info "data elements created #{status.to_json}, creating activity states"

    elements.map do |activity_state, data_element|
      activity, state = activity_state
      element = dhis2.data_elements.find_by(code: data_element[:code])
      activity.activity_states.create(state: state, name: element.name, external_reference: element.id)
    end

    # TODO: package level state

    SynchroniseDegDsWorker.perform_async(project_anchor_id)
  end
end
