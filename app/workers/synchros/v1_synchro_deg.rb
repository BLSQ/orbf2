# frozen_string_literal: true

class Synchros::V1SynchroDeg


    def synchronize(package)
      Rails.logger.info "********** Synchronizing #{package.name} (#{package.id}) - activities #{package.activities.size}"
      @indicators ||= package.project.dhis2_connection.indicators.list(fields: ":all", page_size: 50_000)
      package.package_states.each do |package_state|
        state = package_state.state
        Rails.logger.info "\t ---------------- #{state.name}"
        data_element_ids = data_element_ids_used_for(package, state)
        next if data_element_ids.empty?

        Rails.logger.info "dataelements : #{data_element_ids}"
        created_deg = create_data_element_group(package, state, data_element_ids)
        Rails.logger.info "created #{created_deg}"
        if created_deg
          package_state.deg_external_reference = created_deg.id
          package_state.save!
        end

        created_ds = create_dataset(package, state, data_element_ids)
        if created_ds
          package_state.ds_external_reference = created_ds.id
          package_state.save!
        end

        package
      end
    end

    def data_element_ids_used_for(package, state)
      activity_states = package.activities
                               .flat_map { |activity| activity.activity_state(state) }
                               .reject(&:nil?)
      data_element_ids = activity_states.select(&:data_element_related?).map(&:data_element_id)
      data_element_ids += indicators_data_element_references(@indicators, activity_states)
      data_element_ids.reject(&:nil?).reject(&:empty?).uniq
    end

    def create_data_element_group(package, state, data_element_ids)
      created_deg = nil
      begin
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
        puts "**************************************** #{deg_id}"
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
        puts deg.to_json
        Rails.logger.warn("failed create_data_element_group " + e.message + "\n" +
                           e&.response&.body + "\n" + +e&.response&.request&.payload.inspect)

        return created_deg
      end
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
      created_ds = nil
      ds_id = package.package_states.find { |ps| ps.state == state }.ds_external_reference
      if ds_id
        created_ds = begin
                       dhis2.data_sets.find(ds_id)
                     rescue StandardError
                       nil
                     end
      end
      if created_ds.nil?
        payload = ds
        status = dhis2.data_sets.create(payload)
      end

      created_ds = dhis2.data_sets.find_by(name: created_ds&.name || ds_name)

      target_ds = OpenStruct.new(ds.first)

      created_ds.name = target_ds.name
      created_ds.short_name = target_ds.short_name
      created_ds.code = target_ds.code
      created_ds.period_type = target_ds.period_type
      created_ds.open_future_periods = target_ds.open_future_periods

      Rails.logger.info JSON.pretty_generate(created_ds.to_h)
      created_ds[:data_set_elements] = ds.first[:data_elements].map do |de|
        { "data_element" => de }
      end
      created_ds.update
      raise "dataset not created #{ds_name} : #{ds} : #{status.inspect}" unless created_ds

      # due to v2.20 compat, looks data_elements is not always taken into accounts
      if created_ds.data_elements
        existing = created_ds.data_elements.map { |de| de["id"] }
        data_element_ids.map do |data_element_id|
          next if existing.include?(data_element_id)

          begin
            Rails.logger.info "adding element #{data_element_id} to #{created_ds.id} #{created_ds.name}"
            created_ds.add_relation(:dataElements, data_element_id)
          rescue StandardError => e
            Rails.logger.info "failed to associate data_element_id with dataset #{e.message}"
          end
        end
    end
      created_ds
    rescue RestClient::Exception => e
      raise "Failed to create dataset #{ds} #{e.message} with #{package.project.dhis2_url} #{e.response.body}"
    end

    def indicators_data_element_references(indicators, activity_states)
      indicator_references = Set.new(activity_states.select(&:kind_indicator?).select(&:origin_data_value_sets?).map(&:external_reference))
      parser_klazz = Orbf::RulesEngine::IndicatorExpressionParser
      dataelement_references = indicators.select { |i| indicator_references.include?(i.id) }
                                         .map { |indicator| parser_klazz.parse_expression(indicator.numerator) }
                                         .flatten
                                         .compact
                                         .map(&:data_element)
      Rails.logger.info "Adding indicator's data elements #{indicator_references.to_a} => #{dataelement_references}"
      dataelement_references
    end
  end
