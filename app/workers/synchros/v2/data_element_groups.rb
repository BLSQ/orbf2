# frozen_string_literal: true

class Synchros::V2::DataElementGroups
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
      deg_code = "ORBF-#{package.name}"[0..49]
      deg_name = "ORBF - #{package.name}"
      deg = [
        {
          name:          deg_name,
          short_name:    deg_code,
          code:          deg_code,
          display_name:  deg_name,
          data_elements: data_element_ids.map do |data_element_id|
            { id: data_element_id }
          end
        }
      ]
      dhis2 = package.project.dhis2_connection
      status = nil
      deg_id = package.deg_external_reference
      puts "**************************************** #{deg_id}"
      if deg_id
        created_deg = dhis2.data_element_groups.find(deg_id)
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
