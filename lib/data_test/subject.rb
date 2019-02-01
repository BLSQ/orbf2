# frozen_string_literal: true

require "uri"

module DataTest
  class Subject
    attr_accessor :project_name, :project_id, :year, :quarter, :orgunit_ext_id

    def initialize(project_name, hash)
      if (url = hash["url"])
        hash = Subject.url_to_hash(url)
      end
      @project_name = project_name
      @project_id = hash.fetch("project_id")
      @year = hash.fetch("year")
      @quarter = hash.fetch("quarter")
      @orgunit_ext_id = hash.fetch("orgunit_ext_id")
    end

    def self.url_to_hash(url)
      uri = URI.parse(url)
      parts = uri.query.split("&").each_with_object({}) do |s, r|
        key, value = s.split("=")
        key = "orgunit_ext_id" if key == "entity"
        r[key] = value
      end
      parts.merge!("project_id" => uri.path.match(%r{projects/(\d+)/})[1])
    end

    def name
      "#{project_name}-#{orgunit_ext_id}"
    end
  end
end
