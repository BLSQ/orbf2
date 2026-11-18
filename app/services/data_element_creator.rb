# frozen_string_literal: true

# Creates an aggregate data element (default category combo) in the dhis2 of a
# project and returns its dhis2 id.
#
#   DataElementCreator.new(project).call(
#     name: "Consultation externe - indigent - taux validation",
#     short_name: "Cons ext indigent - taux val", code: "quant98_taux_validation",
#     value_type: "UNIT_INTERVAL", aggregation_type: "AVERAGE"
#   )
#
# Raises DataElementCreator::Error with the reasons when the attributes are invalid
# or dhis2 refuses the data element (name, short name or code already used,...).
class DataElementCreator
  class Error < StandardError; end

  VALUE_TYPES = %w[
    NUMBER
    INTEGER
    INTEGER_POSITIVE
    INTEGER_ZERO_OR_POSITIVE
    INTEGER_NEGATIVE
    UNIT_INTERVAL
    PERCENTAGE
  ].freeze

  AGGREGATION_TYPES = %w[SUM AVERAGE AVERAGE_SUM_ORG_UNIT LAST MIN MAX NONE].freeze

  # dhis2 column sizes
  MAX_LENGTHS = { name: 230, short_name: 50, code: 50 }.freeze

  def initialize(project)
    @project = project
  end

  def call(attributes)
    element = normalize(attributes)
    errors = validation_errors(element)
    raise Error, errors.join(", ") if errors.any?

    dhis2 = project.dhis2_connection
    status = create_in_dhis2(dhis2, element)
    refused!(status.raw_status) unless status.success?

    created = dhis2.data_elements.find_by(code: element[:code])
    raise Error, "data element #{element[:code]} created but not found by its code" unless created

    created.id
  end

  private

  attr_reader :project

  def normalize(attributes)
    attributes.to_h.symbolize_keys.slice(:name, :short_name, :code, :value_type, :aggregation_type)
              .transform_values { |value| value.to_s.strip }
  end

  def validation_errors(element)
    length_errors(element) + type_errors(element)
  end

  def length_errors(element)
    MAX_LENGTHS.filter_map do |field, max|
      value = element[field]
      if value.blank?
        "#{field} is required"
      elsif value.length > max
        "#{field} is too long (#{value.length}, max #{max})"
      end
    end
  end

  def type_errors(element)
    value = element[:value_type]
    aggregation = element[:aggregation_type]
    [
      ("unsupported value type #{value}" if VALUE_TYPES.exclude?(value)),
      ("unsupported aggregation type #{aggregation}" if AGGREGATION_TYPES.exclude?(aggregation))
    ].compact
  end

  def create_in_dhis2(dhis2, element)
    dhis2.data_elements.create([element])
  rescue RestClient::ExceptionWithResponse => e
    # recent dhis2 answer a refused import with a 409 and the import report as body
    body = begin
      JSON.parse(e.response&.body.to_s)
    rescue JSON::ParserError
      {}
    end
    refused!(Dhis2::Case.deep_change(body, :underscore))
  end

  def refused!(report)
    raise Error, "dhis2 refused the data element: #{error_messages(report)}"
  end

  # error_reports of the metadata import report, whatever its nesting (2.35: type_reports at
  # the root, later versions: under response)
  def error_messages(report)
    messages = error_reports(report).filter_map { |error| error["message"] }.uniq
    messages.presence&.join(", ") || report.to_json.truncate(500)
  end

  def error_reports(node)
    case node
    when Hash then Array(node["error_reports"]) + error_reports(node.values)
    when Array then node.flat_map { |value| error_reports(value) }
    else []
    end
  end
end
