module Invoicing
  class ActivityResult < Struct.new(:package, :activity, :solution, :date)
    def to_s
      "#{package.name} #{activity.name} #{date} #{solution}"
    end
    def to_json(options)
      to_h.to_json(options)
    end
  end
end
