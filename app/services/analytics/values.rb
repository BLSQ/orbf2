module Analytics
  class Values < Struct.new(:claimed, :verified, :validated, :date)
    def to_facts
      {
        "claimed"  => claimed,
        "verified"  => verified,
        "validated" => validated
      }
    end
  end
end
