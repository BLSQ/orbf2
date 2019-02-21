# frozen_string_literal: true

module Rules
  class ValuesMocker
    def self.build_mock_values(expression, available_variables_for_values)
      variables = {}
      available_variables_for_values
        .select { |name| name.ends_with?("_values") }
        .each do |variable_name|
          raise "please don't add extra spaces in '%{#{variable_name}}'" if variable_name.include?(" ")
          next unless expression.include?(variable_name)

          variables[variable_name.to_sym] = mock_array(variable_name)
        end
      variables
      end

    def self.mock_array(variable_name)
      if variable_name.end_with?("_current_quarter_values")
        "1 , 2 , 3"
      else
        matched_window = variable_name.match(/.last_(?<length>\d)_(month|quarter)s_window_values/)
        if matched_window
          range = 1..(Integer(matched_window[:length]))
          range.map(&:to_s).join(" , ")
        else
          "1 , 2"
        end
      end
    end

    def self.mock_values(expression, available_variables_for_values)
      variables = build_mock_values(expression, available_variables_for_values)
      expression % variables
    rescue ArgumentError => e
      raise e.message
    end
  end
end
