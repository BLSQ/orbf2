namespace :fix_groups do
  desc "update groupset for primary and secondary"

  def snapshot(project_anchor, kind:)
    project_anchor.dhis2_snapshots.where(
      kind: kind
    ).first
  end

  GROUP_SET_TO_ADD = {
    "lastUpdated" => "2018-06-07T06:24:03.974",
    "id" => "h13NHwS8ljU",
    "href" => "https://dhis2.fbrcameroun.org/api/24/organisationUnitGroupSets/h13NHwS8ljU",
    "created" => "2017-05-31T14:50:45.034",
    "name" => "Sub-Contracted", "shortName" => "Sub-Contracted",
    "dimensionType" => "ORGANISATION_UNIT_GROUP_SET", "displayName" => "Sub-Contracted",
    "publicAccess" => "rw------", "displayShortName" => "Sub-Contracted", "externalAccess" => false,
    "dimension" => "h13NHwS8ljU", "allItems" => false, "compulsory" => false, "dataDimension" => true,
    "access" => {
      "read" => true, "update" => true, "externalize" => false,
      "delete" => true, "write" => true, "manage" => true
    },
    "user" => { "id" => "M5zQapPyTZI" }, "translations" => [],
    "organisationUnitGroups" => [{ "id" => "TSMwQ2oCDL1" }, { "id" => "g5G55uqglob" }],
    "userGroupAccesses" => [], "attributeValues" => [],
    "items" => [{ "id" => "TSMwQ2oCDL1" }, { "id" => "g5G55uqglob" }]
  }.freeze

  def ensure_content(snaphot, dhis2_id, attribute_key, content)
    rec = snaphot.content_for_id(dhis2_id)
    rec[attribute_key] = content unless rec[attribute_key] == content
  end

  def groups
    @groups ||= OpenStruct.new(
      primary:   OpenStruct.new(id: "TSMwQ2oCDL1"),
      secondary: OpenStruct.new(id: "g5G55uqglob")
    )
  end

  def groupsets
    @groupsets ||= begin
      groupsets = OpenStruct.new({})
      groupsets.primary = OpenStruct.new(
        id:     "jha5hRorWlK"
      ).freeze

      groupsets.subcontracted = OpenStruct.new(
        id:     "h13NHwS8ljU"
      ).freeze

      groupsets.freeze
    end
  end

  task fix: :environment do
    project_anchor_id = 6
    project_anchor = ProjectAnchor.find(project_anchor_id)

    project_anchor.with_lock do
      puts "groups"
      project_anchor.dhis2_snapshots.where(kind: "organisation_unit_groups").each do |groups_snapshot|
        puts "fixing groups #{groups_snapshot.id} : #{groups_snapshot.year}#{groups_snapshot.month}"
        ensure_content(groups_snapshot, groups.primary.id,
                       "organisation_unit_group_set", "id" => groupsets.subcontracted.id)
        ensure_content(groups_snapshot, groups.secondary.id,
                       "organisation_unit_group_set", "id" => groupsets.subcontracted.id)
        groups_snapshot.save!
      end

      puts "groupsets"

      project_anchor.dhis2_snapshots.where(kind: "organisation_unit_group_sets").each do |groupset_snapshot|
        puts "fixing groupsets #{groupset_snapshot.id} : #{groupset_snapshot.year}#{groupset_snapshot.month}"

        groupset = groupset_snapshot.content_for_id(groupsets.primary.id)
        if groupset
          groupset["organisation_unit_groups"] = GROUP_SET_TO_ADD["organisation_unit_groups"]
        else
          groupset_snapshot.append_content(GROUP_SET_TO_ADD)
        end
        groupset_snapshot.save!
      end
    end
  end
end
