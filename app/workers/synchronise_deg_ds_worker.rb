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
    Rails.logger.info "********** Synchronizing #{package.name} (#{package.id}) - activities #{package.activities.size}"
    @indicators ||= package.project.dhis2_connection.indicators.fetch_paginated_data(fields: ":all")
    package.package_states.each do |package_state|
      state = package_state.state
      Rails.logger.info "\t ---------------- #{state.name}"
      activity_states = package.activities.map { |activity| activity.activity_state(state) }.reject(&:nil?)
      data_element_ids = activity_states.select(&:kind_data_element?).map(&:external_reference).flatten.reject(&:nil?).reject(&:empty?)
      data_element_ids += indicators_data_element_references(@indicators, activity_states)
      data_element_ids = data_element_ids.uniq
      next if data_element_ids.empty?

      create_dataset(package, package_state, data_element_ids)
      package
    end
  end

  def create_dataset(package, package_state, data_element_ids)
    state = package_state.state
    created_ds = nil
    dhis2 = package.project.dhis2_connection
    if package_state.ds_external_reference
      created_ds = dhis2.data_sets.find(package_state.ds_external_reference)
    else
      ds_code = "#{state.code}-#{package.name}"[0..49]
      ds_name = "#{state.name.pluralize} - #{package.name}"
      ds = {
        name:          ds_name,
        short_name:    ds_code,
        code:          ds_code,
        period_type:   package.frequency.capitalize,
        display_name:  ds_name,
        data_elements: data_element_ids.map do |data_element_id|
                         { id: data_element_id }
                       end
      }

      ds[:data_set_elements] = ds[:data_elements].map do |de|
        { "data_element" => de }
      end
      created_ds = dhis2.data_sets.create(ds)
      package_state.update_attributes!(ds_external_reference: created_ds.id)
    end
    created_ds.add_data_elements(data_element_ids)
  rescue Dhis2::RequestError => e
    raise "Failed to create/update dataset #{ds} #{e.message} with #{package.project.dhis2_url} #{e.response.body}"
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
