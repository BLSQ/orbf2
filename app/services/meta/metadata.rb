module Meta
  class Metadata
    attr_reader :dhis2_id, :dhis2_name, :dhis2_short_name, :dhis2_code,
                :orbf_name, :orbf_short_name, :orbf_code, :orbf_type,
                :activity_state, :package, :formula_mapping, :payment_rule

    def initialize(
        dhis2_id:, dhis2_name:, dhis2_short_name:, dhis2_code:,
        activity_state: nil, package: nil, formula_mapping: nil, payment_rule: nil,
        orbf_name:, orbf_short_name:, orbf_code:, orbf_type:
    )
      @orbf_name = orbf_name
      @orbf_short_name = orbf_short_name
      @orbf_code = orbf_code
      @orbf_type = orbf_type
      @dhis2_code = dhis2_code
      @dhis2_name = dhis2_name
      @dhis2_short_name = dhis2_short_name
      @dhis2_id = dhis2_id
      @formula_mapping = formula_mapping
      @activity_state = activity_state
      @package = package
      @payment_rule = payment_rule
    end

    def dhis2_type
      "data_element"
    end

    def package_name
      package&.name
    end

    def formula
      @formula_mapping&.formula
    end
  end
end
