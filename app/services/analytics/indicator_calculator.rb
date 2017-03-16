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
          value["dataElement"],
          value["period"],
          value["orgUnit"],
          value["categoryOptionCombo"]
        ]
      end
      indexed_values_without_category = values.group_by do |value|
        [
          value["dataElement"],
          value["period"],
          value["orgUnit"]
        ]
      end
      period_orgunits = values.map { |value| [value["period"], value["orgUnit"]] }.uniq.sort

      parsed_expressions.map do |indicator_id, expressions_to_sum|
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
          values_for_entity = expressions_to_sum.select { |e| e[:category_combo].nil? }
                                                .map do |expression|
            values_for_entity += indexed_values_without_category[
              [expression[:data_element],
               period,
               orgunit]
             ]
          end

          value = values_for_entity.flatten.compact.map { |v| v["value"].to_f }.sum
          #puts "calculating #{indicator_id} for pe:#{period} ou:#{orgunit} => #{values_for_entity} => #{value}"
          {
            "dataElement":         indicator_id,
            "period":              period,
            "orgUnit":             orgunit,
            "value":               value,
            "categoryOptionCombo": nil
          }
        end
      end.flatten
    end
  end
end
