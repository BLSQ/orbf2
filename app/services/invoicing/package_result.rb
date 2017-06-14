module Invoicing
  class PackageResult < Struct.new(:package, :solution, :variables)
    attr_accessor :frequency

    def to_s
      "#{package.name} #{frequency} #{solution}"
    end

    def to_json(options)
      to_h.to_json(options)
    end
  end
end
