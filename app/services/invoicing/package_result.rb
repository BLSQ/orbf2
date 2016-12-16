module Invoicing
  class PackageResult < Struct.new(:package, :solution)
    def to_s
      "#{package.name} #{solution}"
    end
  end
end
