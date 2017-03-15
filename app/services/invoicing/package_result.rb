module Invoicing
  class PackageResult < Struct.new(:package, :solution)
    def to_s
      "#{package.name} #{solution}"
    end

    def to_json(options)
      to_h.to_json(options)
    end
  end
end
