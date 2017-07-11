require "csv"
module Decision
  class Rule
    def initialize(headers, row)
      @headers = headers
      @row = headers.map do |header|
        [header, row[header] ? row[header].strip : nil]
      end.to_h
    end

    def matches?(hash)
      headers("in:").all? { |header| hash[header] == @row[header] || @row[header].nil? }
    end

    def headers(type)
      @headers.select { |header| header.start_with?(type) }
    end

    def apply(hash = {})
      headers("out:").each do |header|
        hash[header.slice(4..-1)] = @row[header]
      end
      hash
    end

    def [](key)
      @row[key]
    end
  end

  class Table
    def initialize(csv_string)
      csv = CSV.parse(csv_string, headers: true)
      @headers = csv.headers

      @rules = csv.map do |row|
        Rule.new(@headers, row)
      end
    end

    def find!(raw_hash)
      values = find(raw_hash)
      raise "no extra facts for #{raw_hash} in #{@headers}" unless values
      values
    end

    def find(raw_hash)
      hash = raw_hash.map do |k, v|
        ["in:#{k}", v]
      end.to_h
      @rules.each do |rule|
        next unless rule.matches?(hash)
        return rule.apply
      end
      nil
    end

    def headers(type = nil)
      if type
        @headers.select { |header| header.start_with?(type.to_s) }.map { |h| h.split(":")[1] }
      else
        @headers
      end
    end

    attr_reader :rules
  end
end
