module Invoicing
  class ActivityResult < Struct.new(:package, :activity, :solution, :date)
    def to_s
      "#{package.name} #{activity.name} #{date} #{solution}"
    end
  end
end
