# frozen_string_literal: true

module Descriptor
  class ActivityDescription
    attr_reader :package
    def initialize(package)
      @package = package
    end

    def activity_descriptors
      package.activities.map do |activity|
        activity_descriptor = {
          name: activity.name,
          code: activity.code
        }
        fill_states(activity, activity_descriptor)
        fill_formulas(activity, activity_descriptor)
        activity_descriptor
      end
    end

    def fill_states(activity, activity_descriptor)
      package.states.each do |state|
        actitivity_state = activity.activity_state(state)
        if actitivity_state&.external_reference.present?
          activity_descriptor[state.code] = actitivity_state.external_reference
        end
      end
    end

    def fill_formulas(activity, activity_descriptor)
      package.activity_rule.formulas.each do |formula|
        mapping = formula.formula_mapping(activity)
        activity_descriptor[formula.code] = mapping.external_reference if mapping
      end
    end
  end
end
