# frozen_string_literal: true

class Synchros::V2::DataElementGroups < Synchros::Base
  def synchronize(package)
    Rails.logger.info "********** Synchronizing #{package.name} (#{package.id}) - activities #{package.activities.size}"
    @indicators ||= package.project.dhis2_connection.indicators.list(fields: "id,name,numerator", page_size: 50_000)

    data_element_ids = data_element_ids_used_for(package)
    return if data_element_ids.empty?

    Rails.logger.info "dataelements : #{data_element_ids}"
    created_deg = create_data_element_group(package, data_element_ids)
    Rails.logger.info "created/updated #{created_deg}"
    package.update!(deg_external_reference: created_deg.id) if created_deg

    package
  end

  def data_element_ids_used_for(package)
    activity_states = package.activities
                             .flat_map(&:activity_states)
                             .reject(&:nil?)
    data_element_ids = activity_states.select(&:data_element_related?).map(&:data_element_id)
    data_element_ids += indicators_data_element_references(@indicators, activity_states)
    data_element_ids.reject(&:nil?).reject(&:empty?).uniq
  end

  def create_data_element_group(package, data_element_ids)
    created_deg = nil
    begin
      deg_code = "hesabu-#{package.id}"
      deg_name = "ORBF - #{package.id} - #{package.name}"
      deg =
        {
          name:          deg_name,
          short_name:    deg_code,
          code:          deg_code,
          display_name:  deg_name,
          data_elements: data_element_ids.map do |data_element_id|
            { id: data_element_id }
          end
        }

      dhis2 = package.project.dhis2_connection
      status = nil
      deg_id = package.deg_external_reference
      created_deg = dhis2.data_element_groups.find_by(code: deg_code)
      puts "**************************************** #{deg_id}"
      unless created_deg
        status = dhis2.data_element_groups.create([deg])
        created_deg = dhis2.data_element_groups.find_by(code: deg_code)
      end

      raise "data element group not created #{deg_name} : #{deg} : #{status.inspect}" unless created_deg

      created_deg.name = deg[:name]
      created_deg.data_elements = deg[:data_elements]
      created_deg.update

      created_deg
    rescue RestClient::Exception => e
      puts deg.to_json
      Rails.logger.warn("failed create_data_element_group " + e.message + "\n" +
                         e&.response&.body + "\n" + +e&.response&.request&.payload.inspect)

      return created_deg
    end
  end
end
