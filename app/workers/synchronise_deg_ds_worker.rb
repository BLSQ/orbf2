class SynchroniseDegDsWorker
  include Sidekiq::Worker

  def perform(project_anchor_id, now = Time.now.utc)
    project_anchor = ProjectAnchor.find(project_anchor_id)
    project = project_anchor.latest_draft || project_anchor.projects.for_date(now)

    project.packages.each do |package|
      synchronize(package)
    end
    Dhis2SnapshotWorker.perform_async(project_anchor_id)
  end

  def synchronize(package)
    puts "********** Synchronizing #{package.name} (#{package.id}) - activities #{package.activities.size}"
    package.package_states.each do |package_state|
      state = package_state.state
      puts "\t ---------------- #{state.name}"
      activity_states = package.activities.map { |activity| activity.activity_state(state) }.reject(&:nil?)
      created_deg = create_data_element_group(package, state, activity_states.map(&:external_reference))
      puts "created #{created_deg}"
      package_state.deg_external_reference = created_deg.id
      package_state.save!

      created_ds = create_dataset(package, state, activity_states.map(&:external_reference))
      package_state.ds_external_reference = created_ds.id
      package_state.save!
      puts "updated package_state ds and deg external_reference to #{created_deg.id}  #{created_ds.id} #{package_state.inspect}"
      package
    end
  end

  def create_data_element_group(package, state, data_element_ids)
    deg_code = "#{state.code}-#{package.name}"[0..49]
    deg_name = "#{state.name.pluralize} - #{package.name}"
    deg = [
      { name:          deg_name,
        short_name:    deg_code,
        code:          deg_code,
        display_name:  deg_name,
        data_elements: data_element_ids.map do |data_element_id|
          { id: data_element_id }
        end }
    ]
    dhis2 = package.project.dhis2_connection
    status = dhis2.data_element_groups.create(deg)
    created_deg = dhis2.data_element_groups.find_by(name: deg_name)
    raise "data element group not created #{deg_name} : #{deg} : #{status.inspect}" unless created_deg
    return created_deg
  rescue RestClient::Exception => e
    raise "Failed to create data element group #{deg} #{e.message} with #{package.project.dhis2_url}  #{e.response.body}"
  end


  def create_dataset(package, state, data_element_ids)
    ds_code = "#{state.code}-#{package.name}"[0..49]
    ds_name = "#{state.name.pluralize} - #{package.name}"
    ds = [
      { name:          ds_name,
        short_name:    ds_code,
        code:          ds_code,
        display_name:  ds_name,
        data_elements: data_element_ids.map do |data_element_id|
          { id: data_element_id }
        end }
    ]
    dhis2 = package.project.dhis2_connection
    status = dhis2.data_sets.create(ds)
    created_ds = dhis2.data_sets.find_by(name: ds_name)
    raise "dataset not created #{ds_name} : #{ds} : #{status.inspect}" unless created_ds
    # due to v2.20 compat, looks data_elements is not always taken into accounts
    data_element_ids.map do |data_element_id|
      puts "adding element #{data_element_id} to #{created_ds.id} #{created_ds.name}"
      created_ds.add_relation(:dataElements, data_element_id)
    end
    return created_ds
  rescue RestClient::Exception => e
    raise "Failed to create dataset #{ds} #{e.message} with #{package.project.dhis2_url} #{e.response.body}"
  end
end
