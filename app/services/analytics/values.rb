module Analytics
  class Values < Struct.new(:declared, :verified, :validated, :date)
    def to_facts
      {
        "declared"  => declared,
        "verified"  => verified,
        "validated" => validated
      }
    end
  end
end
