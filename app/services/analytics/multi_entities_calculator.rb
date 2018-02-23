module Analytics
  class MultiEntitiesCalculator
    class MultiEntitiesResult < ValueObject
      attributes :activity, :org_unit_id, :solution
    end

    def initialize(org_unit_ids, package, values, period)
      @org_unit_ids = org_unit_ids
      @package = package
      @values = values
      @period = period
      @solver = ::Rules::Solver.new
    end

    def calculate
      if package.multi_entities_rule&.formulas&.any?
        build_results
      else
        []
      end
    end

    private

    def build_results
      periods = [period.to_dhis2, period.to_quarter.to_dhis2]
      org_unit_ids.each_with_object([]) do |org_unit_id, array|
        puts "*****************************"
        orgunit_values = values.select { |val| periods.include?(val.period) && val.org_unit == org_unit_id }
        package.activities.each do |activity|
          array.push(
            MultiEntitiesResult.with(
              activity:   activity,
              org_unit_id: org_unit_id,
              solution:   build_and_solve(activity, orgunit_values)
            )
          )
        end
      end
    end

    def build_and_solve(activity, orgunit_values)
      hash = {}
      activity.activity_states.select(&:external_reference?).map do |activity_state|
        activity_values = orgunit_values.select { |val| val.data_element == activity_state.external_reference }
        hash[activity_state.state.code] = activity_values.map(&:value).map(&:to_f).sum
      end
      activity.activity_states.select(&:kind_formula?).each do |activity_state|
        hash[activity_state.state.code] = activity_state.formula
      end

      package.multi_entities_rule.formulas.each do |formula|
        hash[formula.code] = formula.expression
      end
      package.states.each do |state|
        hash[state.code] ||= 0
      end
      solution = @solver.solve!("multientities for #{package.name}", hash)
      solution
    end

    attr_reader :org_unit_ids, :package, :period, :values
  end
end
