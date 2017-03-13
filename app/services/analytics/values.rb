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

    def facts
      @facts
    end
  end

  def self.from(claimed, verified, validated, date)
    Values.new(
      "claimed"  => claimed,
      "verified"  => verified,
      "validated" => validated
    )
  end


end
