class Synchros::Base
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
