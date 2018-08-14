# frozen_string_literal: true

class SynchroniseDegDsWorker
  include Sidekiq::Worker
  include Sidekiq::Throttled::Worker

  sidekiq_options retry: 1

  sidekiq_throttle(
    concurrency: { limit: 1 },
    key_suffix:  ->(project_anchor_id, _time= Time.now.utc) { project_anchor_id }
  )

  def perform(project_anchor_id, now = Time.now.utc)
    project_anchor = ProjectAnchor.find(project_anchor_id)
    project = project_anchor.latest_draft || project_anchor.projects.for_date(now)

    project.packages.each do |package|
      synchronize(package)
    end
    Dhis2SnapshotWorker.perform_async(project_anchor_id)
  end

  def synchronize(package)
    Rails.logger.info "********** Synchronizing #{package.name} (#{package.id}) - activities #{package.activities.size}"
    @indicators ||= package.project.dhis2_connection.indicators.list(fields: ":all", page_size: 50_000)
    package.package_states.each do |package_state|
      state = package_state.state
      Rails.logger.info "\t ---------------- #{state.name}"
      activity_states = package.activities.map { |activity| activity.activity_state(state) }.reject(&:nil?)
      data_element_ids = activity_states.select(&:kind_data_element?).map(&:external_reference).flatten.reject(&:nil?).reject(&:empty?)
      data_element_ids += indicators_data_element_references(@indicators, activity_states)
      data_element_ids = data_element_ids.uniq
      next if data_element_ids.empty?
      Rails.logger.info "dataelements : #{data_element_ids}"
      created_deg = create_data_element_group(package, state, data_element_ids)
      Rails.logger.info "created #{created_deg}"
      package_state.deg_external_reference = created_deg.id
      package_state.save!

      created_ds = create_dataset(package, state, data_element_ids)
      package_state.ds_external_reference = created_ds.id
      package_state.save!
      Rails.logger.info "updated package_state ds and deg external_reference to #{created_deg.id}  #{created_ds.id} #{package_state.inspect}"
      package
    end
  end

  def create_data_element_group(package, state, data_element_ids)
    deg_code = "ORBF-#{state.code}-#{package.name}"[0..49]
    deg_name = "ORBF - #{state.name.pluralize.humanize} - #{package.name}"
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
    status = nil
    deg_id = package.package_states.find { |ps| ps.state == state }.deg_external_reference
    if deg_id
      created_deg = dhis2.data_element_groups.find(deg_id)
      created_deg.update_attributes(deg.first) # rubocop:disable Rails/ActiveRecordAliases
    else
      status = dhis2.data_element_groups.create(deg)
    end
    created_deg = dhis2.data_element_groups.find_by(name: deg_name)
    raise "data element group not created #{deg_name} : #{deg} : #{status.inspect}" unless created_deg
    created_deg
  rescue RestClient::Exception => e
    raise "Failed to create data element group #{deg} #{e.message} with #{package.project.dhis2_url}  #{e.response.body}"
  end

  def create_dataset(package, state, data_element_ids)
    ds_code = "ORBF-#{state.code}-#{package.name}"[0..49]
    ds_name = "ORBF - #{state.name.pluralize.humanize} - #{package.name}"
    ds = [
      { name:                ds_name,
        short_name:          ds_code,
        code:                ds_code,
        period_type:         package.frequency.capitalize,
        display_name:        ds_name,
        open_future_periods: 13,
        data_elements:       data_element_ids.map do |data_element_id|
          { id: data_element_id }
        end }
    ]
    ds.first[:data_set_elements] = ds.first[:data_elements].map do |de|
      { "data_element" => de }
    end
    dhis2 = package.project.dhis2_connection

    status = nil

    ds_id = package.package_states.find { |ps| ps.state == state }.ds_external_reference
    if ds_id
      created_ds = dhis2.data_sets.find(ds_id)
      created_ds.update_attributes(ds.first) # rubocop:disable Rails/ActiveRecordAliases
    else
      status = dhis2.data_sets.create(ds)
    end

    status =
      created_ds = dhis2.data_sets.find_by(name: ds_name)
    Rails.logger.info JSON.pretty_generate(created_ds.to_h)
    created_ds[:data_set_elements] = ds.first[:data_elements].map do |de|
      { "data_element" => de }
    end
    created_ds.update
    raise "dataset not created #{ds_name} : #{ds} : #{status.inspect}" unless created_ds
    # due to v2.20 compat, looks data_elements is not always taken into accounts
    data_element_ids.map do |data_element_id|
      begin
        Rails.logger.info "adding element #{data_element_id} to #{created_ds.id} #{created_ds.name}"
        created_ds.add_relation(:dataElements, data_element_id)
      rescue StandardError => e
        Rails.logger.info "failed to associate data_element_id with dataset #{e.message}"
      end
    end
    created_ds
  rescue RestClient::Exception => e
    raise "Failed to create dataset #{ds} #{e.message} with #{package.project.dhis2_url} #{e.response.body}"
  end

  def indicators_data_element_references(indicators, activity_states)
    indicator_references = Set.new(activity_states.select(&:kind_indicator?).map(&:external_reference))
    dataelement_references = indicators.select { |i| indicator_references.include?(i.id) }
                                       .map { |indicator| Analytics::IndicatorCalculator.parse_expression(indicator.numerator) }
                                       .flatten
                                       .compact
                                       .map { |expr| expr[:data_element] }
    Rails.logger.info "Adding indicator's data elements #{indicator_references.to_a} => #{dataelement_references}"
    dataelement_references
  end
end
