namespace :activities do
  desc "update names of activity states"
  task resync: :environment do
    project = Project.find(ENV.fetch("PROJECT_ID"))
    data_compound = project.project_anchor.data_compound_for(DateTime.now)

    project.activities.flat_map(&:activity_states).each do |activity_state|
      next unless activity_state.external_reference
      de = data_compound.data_element(activity_state.external_reference)
      next unless de
      activity_state.update!(name: de.name)
    end
  end
end
