module Analytics
  module Locations
    class LevelScope
      def facts(package)
        variable_states(package).keys
      end

      def to_fake_facts(package)
        facts(package).map { |code| [code.to_sym, "10"] }.to_h
      end

      def facts_values(org_units, package, activity, year_month, service)
        level_dependencies = package.activity_rule.dependencies & facts(package)
        vars = variable_states(package)
        level_dependencies.map do |state_level|
          state = vars[state_level]
          values_for_period = service.facts_for_period(
            package,
            activity,
            Analytics::Timeframe.current.periods(package, year_month),
            [parent_org_unit_id(org_units, state_level, activity, package)]
          )
          [state_level, values_for_period[state.code]]
        end.to_h
      end

      private

      def parent_org_unit_id(org_units, state_level, activity, package)
        level_org_ids = org_units_for_level(org_units, state_level)
        if level_org_ids.size > 1
          raise "Can't calculate multiple parents : #{level_org_ids} : #{activity.name} from #{package.name}"
        end

        level_org_ids.first
      end

      def org_units_for_level(org_units, state_level)
        level = state_level.last.to_i
        org_units.map { |org_unit| to_path(org_unit) }
                 .map { |path| path[level - 1] }
                 .flatten
                 .uniq
      end

      def to_path(org_unit)
        org_unit.path.split("/").reject(&:empty?)
      end

      def variable_states(package)
        states = package.package_states.map(&:state)
        (1..5).each_with_object({}) do |level, result|
          states.each do |state|
            result["#{state.code}_level_#{level}"] = state
            result["#{state.code}_level_#{level}_quarterly"] = state
          end
        end
      end
    end
  end
end
