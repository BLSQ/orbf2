
module Groups
  class UpdateHistory
    attr_reader :project_anchor, :update_params

    def initialize(update_params)
      @update_params = update_params
      @project_anchor = update_params.project_anchor
    end

    def call
      project_anchor.with_lock do
        update_params.compared_months.each do |month|
          snapshots_to_fix = snapshots(month)
          ref = snapshots(update_params.reference_period)
          orgunit_to_fix_ids.each do |orgunit_id|
            puts "PATCHING #{month} for #{orgunit_id}"
            fix(orgunit_id, snapshots_to_fix, ref)
          end
          save(snapshots_to_fix)
        end
      end
    end

    private

    def save(snapshots_to_fix)
      snapshots_to_fix.organisation_unit_group_sets.save_mutation!(whodunnit)
      snapshots_to_fix.organisation_unit_groups.save_mutation!(whodunnit)
      snapshots_to_fix.organisation_units.save_mutation!(whodunnit)
    end

    def whodunnit
      @whodunnit = @update_params.whodunnit
    end

    class Snapshots
      attr_reader :organisation_units, :organisation_unit_groups, :organisation_unit_group_sets
      def initialize(organisation_units:, organisation_unit_groups:, organisation_unit_group_sets:)
        @organisation_units = organisation_units
        @organisation_unit_groups = organisation_unit_groups
        @organisation_unit_group_sets = organisation_unit_group_sets
      end
    end

    def snapshots(period)
      ou_dhis2_snapshot = snapshot(kind: "organisation_units", period: period)

      return nil unless ou_dhis2_snapshot

      Snapshots.new(
        organisation_units:           ou_dhis2_snapshot,
        organisation_unit_groups:     snapshot(
          kind:   "organisation_unit_groups",
          period: period
        ),
        organisation_unit_group_sets: snapshot(
          kind:   "organisation_unit_group_sets",
          period: period
        )
      )
    end

    def snapshot(kind:, period:)
      project_anchor.dhis2_snapshots.where(
        kind:  kind,
        year:  period.year,
        month: period.month
      ).first
    end

    def orgunit_to_fix_ids
      [update_params.reference_period_data["id"]]
    end

    def fix(orgunit_id, snapshots_to_fix, ref)
      groupset_reference_snapshot = ref.organisation_unit_group_sets

      contract_group_set_reference = groupset_reference_snapshot.content_for_id(update_params.groupset_id)

      ou_to_fix = snapshots_to_fix.organisation_units.content_for_id(orgunit_id)
      ou_reference = ref.organisation_units.content_for_id(orgunit_id)
      unless ou_to_fix
        ou_to_fix = JSON.parse(JSON.generate(ou_reference))
        snapshots_to_fix.organisation_units.append_content(ou_to_fix)
      end

      ou_to_fix["organisation_unit_groups"] = ou_reference["organisation_unit_groups"]

      subcontract_groupset_id = update_params.groupset_id
      contract_group_set_to_fix = snapshots_to_fix.organisation_unit_group_sets
                                                  .content_for_id(subcontract_groupset_id)

      group_dhis2_snapshot = snapshots_to_fix.organisation_unit_groups

      ou_reference["organisation_unit_groups"].each do |group_added|
        group_to_fix = group_dhis2_snapshot.content_for_id(group_added["id"])
        if group_to_fix
          ou_to_check = { "id" => orgunit_id }
          unless group_to_fix["organisation_units"].include?(ou_to_check)
            group_to_fix["organisation_units"] << ou_to_check
          end
        else
          # group doesn't exist at all
          group_to_add = ref.organisation_unit_groups
                            .content_for_id(group_added["id"])
          group_dhis2_snapshot.append_content(group_to_add)
        end

        to_check = { "id" => group_added["id"] }
        included_in_to_fix = if subcontract_groupset_id
                               contract_group_set_to_fix["organisation_unit_groups"].include?(to_check)
                             end
        included_in_reference = if contract_group_set_reference
                                  contract_group_set_reference["organisation_unit_groups"].include?(to_check)
                                end

        if included_in_reference && !included_in_to_fix
          contract_group_set_to_fix["organisation_unit_groups"] << to_check
        end
      end
    end
  end
end
