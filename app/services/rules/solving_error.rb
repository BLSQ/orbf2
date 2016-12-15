module Rules
  class SolvingError < StandardError
    attr_reader :facts_and_rules, :original_message

    def initialize(original_message, facts_and_rules)
      @facts_and_rules = facts_and_rules
      @original_message = original_message
    end
  end
end
