namespace :fix_groups do
  desc "update groupset for primary and secondary"

  def snapshot(project_anchor, kind:)
    project_anchor.dhis2_snapshots.where(
      kind: kind
    ).first
  end

  GROUP_SET_TO_ADD = {
    "id" => "jha5hRorWlK",
      "name" => "Primary", "user" => { "id"=>"g3uIciXsaOU" },
      "items" => [{ "id"=>"g5G55uqglob" }, { "id"=>"TSMwQ2oCDL1" }],
      "created" => "2018-03-01T20:05:21.947", "all_items" => false, "dimension" => "jha5hRorWlK",
      "compulsory" => false,
      "short_name" => "Primary", "display_name" => "Primary",
      "last_updated" => "2018-03-01T20:05:21.947",
      "translations" => [], "data_dimension" => true,
      "dimension_type" => "ORGANISATION_UNIT_GROUP_SET",
      "external_access" => false, "attribute_values" => [], "display_short_name" => "Primary", "user_group_accesses" => [],
      "organisation_unit_groups" => [{ "id"=>"g5G55uqglob" }, { "id"=>"TSMwQ2oCDL1" }]
  }.freeze

  def ensure_content(snaphot, dhis2_id, attribute_key, content)
    rec = snaphot.content_for_id(dhis2_id)
    rec[attribute_key] = content unless rec[attribute_key] == content
  end

  task fix: :environment do
    project_anchor_id = 6
    project_anchor = ProjectAnchor.find(project_anchor_id)

    byebug
    project_anchor.with_lock do
      groups = OpenStruct.new(
        primary:   OpenStruct.new(id: "TSMwQ2oCDL1"),
        secondary: OpenStruct.new(id: "g5G55uqglob")
      )
      groupsets = OpenStruct.new({})
      groupsets.primary = OpenStruct.new(
        id:     "jha5hRorWlK"
      ).freeze

      groupsets.subcontracted = OpenStruct.new(
        id:     "h13NHwS8ljU"
      ).freeze

      groupsets.freeze

      puts "groups"
      project_anchor.dhis2_snapshots.where(kind: "organisation_unit_groups").each do |groups_snapshot|
        puts "fixing groups #{groups_snapshot.id} : #{groups_snapshot.year}#{groups_snapshot.month}"
        ensure_content(groups_snapshot, groups.primary.id, "organisation_unit_group_set", "id" => groupsets.primary.id)
        ensure_content(groups_snapshot, groups.secondary.id, "organisation_unit_group_set", "id" => groupsets.primary.id)
        groups_snapshot.save!
      end

      puts "groupsets"

      project_anchor.dhis2_snapshots.where(kind: "organisation_unit_group_sets").each do |groupset_snapshot|
        puts "fixing groupsets #{groupset_snapshot.id} : #{groupset_snapshot.year}#{groupset_snapshot.month}"

        groupset = groupset_snapshot.content_for_id(groupsets.primary.id)
        if groupset
          groupset["organisation_unit_groups"] = GROUP_SET_TO_ADD["organisation_unit_groups"]
        else
          groupset_snapshot.content << { "table"=> GROUP_SET_TO_ADD }
        end
        groupset_snapshot.save!
      end
    end
  end
end
