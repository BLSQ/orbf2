require "csv"
module Decision
  class Rule
    ANY = "*".freeze

    IN_HEADERS = "in:".freeze
    OUT_HEADERS = "out:".freeze

    def initialize(headers, row, index)
      @headers = headers
      @index = index
      @row = headers.map do |header|
        [header, row[header] ? row[header].strip : nil]
      end.to_h
      @headers_by_type = {}
    end

    def matches?(hash)
      headers(IN_HEADERS).all? { |header| hash[header] == @row[header] || @row[header] == ANY }
    end

    def specific_score(_hash)
      header_in = headers(IN_HEADERS)
      star_count = header_in.select { |header| @row[header] == ANY }.size
      [header_in.size - star_count, -1 * @index]
    end

    def headers(type)
      @headers_by_type[type] ||= @headers.select { |header| header.start_with?(type) }
    end

    def apply(hash = {})
      headers(OUT_HEADERS).each do |header|
        hash[header.slice(4..-1)] = @row[header]
      end
      hash
    end

    def [](key)
      @row[key]
    end

    def to_s
      @row
    end

    def inspect
      to_s
    end
  end

  class Table
    attr_reader :rules

    def initialize(csv_string)
      csv = CSV.parse(csv_string, headers: true)
      @headers = csv.headers.compact.map(&:freeze)

      @rules = csv.each_with_index.map do |row, index|
        Rule.new(@headers, row, index)
      end
    end

    def find!(raw_hash)
      values = find(raw_hash)
      raise "no extra facts for #{raw_hash} in #{@headers}" unless values
      values
    end

    def to_in_header(header)
      @@headers ||= {}
      @@headers[header] ||= "in:#{header}".freeze
    end

    def find(raw_hash)
      hash = {}
      raw_hash.map { |k, v| hash[to_in_header(k)] = v }
      matching_rules = @rules.select { |rule| rule.matches?(hash) }

      if matching_rules.any?
        if matching_rules.size > 1
          matching_rules = matching_rules.sort_by { |rule| rule.specific_score(hash) }
        end
        return matching_rules.last.apply
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

    def to_s
      @rules.to_s
    end

    def inspect
      to_s
    end
  end
end
