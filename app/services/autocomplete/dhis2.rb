

module Autocomplete
  class Result
    attr_reader :id, :code, :display_name
    def initialize(id:, code:, display_name:)
      @id = id
      @code = code
      @display_name = display_name
    end
  end
  class Dhis2
    def initialize(project_anchor)
      @project_anchor = project_anchor
    end

    def search(name, kind: "data_elements", limit: 20)
      Dhis2Snapshot.connection.select_all(
        ActiveRecord::Base.send(
          :sanitize_sql_array,
          [SEARCH_QUERY, kind, @project_anchor.id, "%#{name}%", limit]
        )
      ).to_hash.map { |e| Result.new(id: e["id"], code: e["code"], display_name: e["display_name"]) }
    end

    SEARCH_QUERY = "select * from (
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
       where display_name ilike ?
      limit ?".freeze
  end
end
