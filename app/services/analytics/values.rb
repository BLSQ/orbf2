module Analytics
  class Values < Struct.new(:claimed, :verified, :validated, :max_score, :date)
    def to_facts
      {
        "claimed"  => claimed,
        "verified"  => verified,
        "validated" => validated,
        "max_score" => max_score
      }
    end
  end
end
