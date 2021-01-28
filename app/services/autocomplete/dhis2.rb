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
    def search(name, kind: "data_elements", limit: 20, fields: %i[id display_name code])
      unnest_elements_rel = unnested_elements_query(kind: kind)

      query = Dhis2Snapshot.from(unnest_elements_rel)
                           .where("element->'table'->>'display_name' ILIKE ?", "%#{name}%")
                           .limit(limit)

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
    def find(id, kind: "data_elements", fields: %i[id display_name code])
      unnest_elements_rel = unnested_elements_query(kind: kind)

      limit = 20
      query = Dhis2Snapshot.from(unnest_elements_rel)
                           .where("element->'table'->>'id' IN (?)", Array.wrap(id))
                           .limit(limit)

      query_to_results(query, fields)
    end

    # Takes an array of `data_elements` (with `DE_COC_FIELDS`) and
    # decorates them with the matching category combos.
    #
    # Returns an array of Struct.new(:id, :display_name)
    def data_elements_with_category_combos(data_elements, limit_to_coc_with_id: nil)
      category_combo_ids = data_elements.map(&:category_combo__id).uniq
      category_combo_by_id = find(category_combo_ids,
                                  kind:   "category_combos",
                                  fields: %i[
                                    id
                                    display_name
                                    category_option_combos
                                  ]).index_by(&:id)

      combo_klazz = Struct.new(:id, :display_name)
      results = data_elements.each_with_object([]) do |element, result|
        combo = category_combo_by_id[element.category_combo__id]

        # Avoid the default Category Combos (some DHIS use default, some use (default))
        # This is a guess
        if !combo || (combo.display_name == "default" || combo.display_name == "(default)")
          result << element
        else
          combo.category_option_combos.each do |coc_hash|
            next unless limit_to_coc_with_id.nil? || (coc_hash["id"] == limit_to_coc_with_id)

            result << combo_klazz.new(
              [element.id, coc_hash["id"]].join("."),
              [element.display_name, coc_hash["name"]].join(" - ")
            )
          end
        end
      end
    end

    private

    # Will execute the query and map it to a Struct where each of the
    # fields is an attribute.
    #
    # Note: that in order to execute this, this expectes the fields to
    # be in `element->'table', so you can't access normal
    # Dhis2Snapshot values.
    def query_to_results(query, fields)
      to_pluck = fields.map do |key|
        parts = key.to_s.split("__")
        k = parts.map { |part| "'#{part}'" }.join("->")
        Arel.sql("element->'table'->#{k}")
      end
      result_klazz = Struct.new(*fields)

      query.pluck(*to_pluck).map do |a|
        result_klazz.new(*a)
      end
    end

    def unnested_elements_query(kind:)
      # Get the id of the latest snapshot for the correct project_anchor and kind
      max_id_rel = Dhis2Snapshot.where(kind: kind).where(project_anchor_id: @project_anchor).select("id").order(["year","month"]).limit(1)
      Dhis2Snapshot.select("jsonb_array_elements(content) as element").from(Dhis2Snapshot.where(id: max_id_rel))
    end
  end
end
