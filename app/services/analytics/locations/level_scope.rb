module Analytics
  module Locations
    class LevelScope
      def facts(package)
        variable_states(package).keys
      end

      def to_fake_facts(package)
        facts(package).map { |code| [code.to_sym, "10"] }.to_h
      end

      private

      def variable_states(package)
        states = package.package_states.map(&:state)
        (1..5).each_with_object({}) do |level, result|
          states.each do |state|
            result["#{state.code}_level_#{level}"] = state
            result["#{state.code}_level_#{level}_quarterly"] = state
            if package.project.calendar_name == "ethiopian_v2"
              result["#{state.code}_level_#{level}_quarterly_nov"] = state
            end
          end
        end
      end
    end
  end
end
