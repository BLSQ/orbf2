module Invoicing
  class PackageResult < Struct.new(:package, :solution, :variables)
    attr_accessor :frequency

    def to_s
      "#{package.name} #{frequency} #{solution}"
    end

    delegate :to_json, to: :to_h
  end
end
