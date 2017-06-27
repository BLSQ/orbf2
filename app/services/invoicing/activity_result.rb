module Invoicing
  class ActivityResult < Struct.new(:package, :activity, :solution, :date, :variables)
    def to_s
      "#{package.name} #{activity.name} #{date} #{solution}"
    end

    delegate :to_json, to: :to_h
  end
end
