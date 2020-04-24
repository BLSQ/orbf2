# frozen_string_literal: true

module Autocomplete
  class Result
    attr_reader :id, :code, :display_name, :category_combo
    def initialize(id:, code:, display_name:, category_combo: nil)
      @id = id
      @code = code
      @display_name = display_name
      @category_combo = category_combo
    end
  end

  class Dhis2
    def initialize(project_anchor)
      @project_anchor = project_anchor
    end

    # Skip default
    def search(name, kind: "data_elements", limit: 20, fields: [:id, :display_name, :code])
      to_pluck = fields.map do |key|
        parts = key.to_s.split("__")
        k = parts.map{|part| "'#{part}'"}.join("->")
        Arel.sql("element->'table'->#{k}")
      end

      # SELECT  "dhis2_snapshots".* FROM (
      #   SELECT jsonb_array_elements(content) as element FROM (
      #     SELECT "dhis2_snapshots".* FROM "dhis2_snapshots"
      #     WHERE "dhis2_snapshots"."id" IN (
      #       SELECT max(id) FROM "dhis2_snapshots"
      #       WHERE "dhis2_snapshots"."kind" = 'data_elements' AND "dhis2_snapshots"."project_anchor_id" = 1
      #     )) subquery) subquery
      # WHERE (element->'table'->>'display_name' ILIKE '%%')
      # LIMIT 20000

      # Get the id of the latest snapshot for the correct project_anchor and kind
      max_id_rel = Dhis2Snapshot.where(kind: kind).where(project_anchor_id: @project_anchor).select("max(id)")
      unnest_elements_rel = Dhis2Snapshot.select("jsonb_array_elements(content) as element").from(Dhis2Snapshot.where(id: max_id_rel))

      result = Struct.new(*fields)
      Dhis2Snapshot.from(unnest_elements_rel).
        where("element->'table'->>'display_name' ILIKE ?", "%#{name}%").
        limit(limit).
        pluck(*to_pluck).map do |a|
        # r = fields.zip(a).to_h
        # Result.new(id: r[:id], code: r[:code], display_name: r[:display_name], category_combo: r)
        result.new(*a)
      end
    end

    def find(id, kind: "data_elements", fields: [:id, :display_name, :code])
      to_pluck = fields.map do |key|
        parts = key.to_s.split("__")
        k = parts.map{|part| "'#{part}'"}.join("->")
        Arel.sql("element->'table'->#{k}")
      end

      max_id_rel = Dhis2Snapshot.where(kind: kind).where(project_anchor_id: @project_anchor).select("max(id)")
      unnest_elements_rel = Dhis2Snapshot.select("jsonb_array_elements(content) as element").from(Dhis2Snapshot.where(id: max_id_rel))

      limit = 20
      result = Struct.new(*fields)
      Dhis2Snapshot.from(unnest_elements_rel).
        where("element->'table'->>'id' IN (?)", Array.wrap(id)).
        limit(limit).
        pluck(*to_pluck).map do |a|
        # r = fields.zip(a).to_h
        # Result.new(id: r[:id], code: r[:code], display_name: r[:display_name], category_combo: r)
        result.new(*a)
      end
    end
  end
end
