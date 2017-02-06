
class CreateMissingDhis2ElementsWorker
  include Sidekiq::Worker

  def perform(project_anchor_id)
    now = Time.now.utc

    project_anchor = ProjectAnchor.find(project_anchor_id)

    project = project_anchor.projects.for_date(now) || project_anchor.current_draft

    dhis2 = project.dhis2_connection
    data_elements = project.missing_activity_states.map do |activity, states|
      states.map do |state|
        {
          code:         "#{state.code}-#{activity.stable_id}",
          short_name:   "#{state.name}-#{activity.name}"[0..49],
          name:         "#{state.name} - #{activity.name}",
          display_name: "#{state.name} - #{activity.name}"
        }
      end
    end

    puts "About to create missing data elements"
    puts JSON.pretty_generate(data_elements)
    status = dhis2.data_elements.create(data_elements.flatten)
    puts "data elements created #{status}"
  end
end
