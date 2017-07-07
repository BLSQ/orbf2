module Analytics
  class Values
    attr_accessor :date
    attr_reader :facts, :variables

    def initialize(date, facts, variables)
      @facts = facts
      @date = date
      @variables = variables
    end

    def to_facts
      @facts
    end

    def self.from(claimed, verified, validated, max_score, _date)
      Values.new(nil,
                 { "claimed"   => claimed,
                   "verified"  => verified,
                   "validated" => validated,
                   "max_score" => max_score },
                 {})
    end
  end
end
