module Analytics
  class Values
    attr_accessor :date
    def initialize(date, facts)
      @facts = facts
      @date = date
    end

    def to_facts
      @facts
    end

    attr_reader :facts

    def self.from(claimed, verified, validated, max_score, _date)
      Values.new(nil,
                 "claimed"   => claimed,
                 "verified"  => verified,
                 "validated" => validated,
                 "max_score" => max_score)
    end
  end
end
