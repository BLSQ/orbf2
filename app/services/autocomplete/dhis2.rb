# frozen_string_literal: true

module Autocomplete
  class Dhis2
    def initialize(project_anchor)
      @project_anchor = project_anchor
    end

    # SELECT  "dhis2_snapshots".* FROM (
    #   SELECT jsonb_array_elements(content) as element FROM (
    #     SELECT "dhis2_snapshots".* FROM "dhis2_snapshots"
    #     WHERE "dhis2_snapshots"."id" IN (
    #       SELECT max(id) FROM "dhis2_snapshots"
    #       WHERE "dhis2_snapshots"."kind" = 'data_elements'
    #         AND "dhis2_snapshots"."project_anchor_id" = 1
    #     )) subquery) subquery
    # WHERE (element->'table'->>'display_name' ILIKE '%%')
    # LIMIT 20000
    def search(name, kind: "data_elements", limit: 20, fields: [:id, :display_name, :code])
      unnest_elements_rel = unnested_elements_query(kind: kind)

      query = Dhis2Snapshot.from(unnest_elements_rel).
        where("element->'table'->>'display_name' ILIKE ?", "%#{name}%").
        limit(limit)

      query_to_results(query, fields)
    end

    # SELECT  "dhis2_snapshots".* FROM (
    #   SELECT jsonb_array_elements(content) as element FROM (
    #     SELECT "dhis2_snapshots".* FROM "dhis2_snapshots"
    #     WHERE "dhis2_snapshots"."id" IN (
    #       SELECT max(id) FROM "dhis2_snapshots"
    #       WHERE "dhis2_snapshots"."kind" = 'data_elements'
    #         AND "dhis2_snapshots"."project_anchor_id" = 1
    #     )) subquery) subquery
    # WHERE (element->'table'->>'id' IN ('unknownid'))
    # LIMIT 20
    def find(id, kind: "data_elements", fields: [:id, :display_name, :code])
      unnest_elements_rel = unnested_elements_query(kind: kind)

      limit = 20
      query = Dhis2Snapshot.from(unnest_elements_rel).
        where("element->'table'->>'id' IN (?)", Array.wrap(id)).
        limit(limit)

      query_to_results(query, fields)
    end

    private

    def query_to_results(query, fields)
      to_pluck = fields.map do |key|
        parts = key.to_s.split("__")
        k = parts.map{|part| "'#{part}'"}.join("->")
        Arel.sql("element->'table'->#{k}")
      end
      result_klazz = Struct.new(*fields)

      query.pluck(*to_pluck).map do |a|
        result_klazz.new(*a)
      end
    end

    def unnested_elements_query(kind:)
      # Get the id of the latest snapshot for the correct project_anchor and kind
      max_id_rel = Dhis2Snapshot.where(kind: kind).where(project_anchor_id: @project_anchor).select("max(id)")
      Dhis2Snapshot.select("jsonb_array_elements(content) as element").from(Dhis2Snapshot.where(id: max_id_rel))
    end
  end
end
