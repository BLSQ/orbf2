class SynchroniseDegDsWorker
  include Sidekiq::Worker

  def perform(project_anchor_id, now = Time.now.utc)
    project_anchor = ProjectAnchor.find(project_anchor_id)
    project = project_anchor.projects.for_date(now)

    project.packages.each do |package|
      synchronize(package)
    end
  end

  def synchronize(package)
    puts "Synchronizing #{package.name} - activities #{package.activities.size}"
    package.activities.each do |activity|
      puts "\t#{activity.name}"
      package.states.each do |state|
        activity_state = activity.activity_state(state)
        if activity_state
          puts "\t \t#{state.name}\t#{activity_state.name}\t#{activity_state.external_reference}"
        else
          puts "\tWARN no activity state for #{state.name} in #{activity.name} for package #{package.name}"
        end
      end
    end
  end


  def create_data_element_group(data_element_ids)
    deg = [
      { name:          name,
        short_name:    name[0..49],
        code:          name[0..49],
        display_name:  name,
        data_elements: data_element_ids.map do |data_element_id|
          { id: data_element_id }
        end }
    ]
    dhis2 = project.dhis2_connection
    status = dhis2.data_element_groups.create(deg)
    created_deg = dhis2.data_element_groups.find_by(name: name)
    raise "data element group not created #{name} : #{deg} : #{status.inspect}" unless created_deg
    return created_deg
  rescue RestClient::Exception => e
    raise "Failed to create data element group #{deg} #{e.message} with #{project.dhis2_url}"
  end
end
