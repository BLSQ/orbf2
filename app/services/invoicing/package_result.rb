module Invoicing
  class PackageResult < Struct.new(:package, :solution, :variables)
    attr_accessor :frequency

    def inspect
      to_s
    end

    def to_s
      "#{package.name} #{frequency} #{solution.to_json}\n"
    end

    delegate :to_json, to: :to_h
  end
end
