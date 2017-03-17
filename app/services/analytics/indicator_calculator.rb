module Analytics
  class IndicatorCalculator
    class UnsupportedExpressionException < StandardError
      attr_reader :expression, :unsupported
      def initialize(expression, unsupported)
        @expression = expression
        @unsupported = unsupported
        super("Unsupported syntax '#{@unsupported}' in '#{expression}'")
      end
    end

    UNSUPPORTED_FEATURES = ["(", ")", "C{", "-", "/", "*"].freeze
    #  currenty only support sum like  '#{dhjgLt7EYmu.se1qWfbtkmx}+#{xtVtnuWBBLB}'
    def self.parse_expression(indicator_expression)
      unsupported = UNSUPPORTED_FEATURES.select { |f| indicator_expression.include?(f) }
      raise UnsupportedExpressionException.new(indicator_expression, unsupported) if unsupported.any?
      expressions = indicator_expression.split("+")

      expressions.map do |expression|
        data_element_category =  expression.sub('#{', "").sub("}", "")
        data_element, category = data_element_category.split(".").map(&:strip)
        { expression: expression.strip, data_element: data_element, category_combo: category }
      end
    end

    def calculate(parsed_expressions, values)
      indexed_values = values.group_by do |value|
        [
          value.data_element,
          value.period,
          value.org_unit,
          value.category_option_combo
        ]
      end
      indexed_values_without_category = values.group_by do |value|
        [
          value.data_element,
          value.period,
          value.org_unit
        ]
      end
      period_orgunits = values.map { |value| [value.period, value.org_unit] }.uniq
      indicator_values  = parsed_expressions.map do |indicator_id, expressions_to_sum|
        period_orgunits.map do |period, orgunit|

          # handle the dhjgLt7EYmu.se1qWfbtkmx part of {dhjgLt7EYmu.se1qWfbtkmx}+#{xtVtnuWBBLB}
          values_for_entity = expressions_to_sum.map do |expression|
            indexed_values[
              [expression[:data_element],
               period,
               orgunit,
               expression[:category_combo]]
            ]
          end

          # handle the xtVtnuWBBLB part of {dhjgLt7EYmu.se1qWfbtkmx}+#{xtVtnuWBBLB}
          values_for_entity += expressions_to_sum.select { |e| e[:category_combo].nil? }
                                                .map do |expression|
            indexed_values_without_category[
              [expression[:data_element],
               period,
               orgunit]
             ]
          end
          values_for_entity = values_for_entity.flatten.compact
          value = values_for_entity.map { |v| v["value"].to_f }.sum
          #puts "calculating #{indicator_id} for pe:#{period} ou:#{orgunit}  => #{value} (#{expressions_to_sum}) <= #{values_for_entity}"
          OpenStruct.new(
            data_element:          indicator_id,
            period:                period,
            org_unit:              orgunit,
            value:                 value,
            category_option_combo: nil
          )
        end
      end

      indicator_values.flatten
    end
  end
end
