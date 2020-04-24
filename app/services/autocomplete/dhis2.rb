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
        "element->'table'->>'#{key}'"
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

      Dhis2Snapshot.from(unnest_elements_rel).
        where("element->'table'->>'display_name' ILIKE ?", "%#{name}%").
        limit(limit).
        pluck(*to_pluck).map do |id, display_name, code,  _category_option_combos|
        Result.new(id: id, code: code, display_name: display_name, category_combo: nil)
      end
    end

    def find(id, kind: "data_elements")
      Dhis2Snapshot.connection.select_all(
        ActiveRecord::Base.send(
          :sanitize_sql_array,
          [FIND_QUERY, kind, @project_anchor.id, id]
        )
      ).to_hash.map { |e| Result.new(id: e["id"], code: e["code"], display_name: e["display_name"]) }
    end

    FIND_QUERY = "select * from (
      select
        (element->'table'->>'id')::text as id ,
            (element->'table'->>'display_name')::text as display_name,
           (element->'table'->>'code')::text as code
        from (
             select jsonb_array_elements(content) as element
             from dhis2_snapshots
             where
             id=(
                SELECT max(id) FROM dhis2_snapshots
                WHERE kind= ? AND project_anchor_id = ?)
             )
         as elements
      ) as dataelements
       where id = ?"
  end
end
