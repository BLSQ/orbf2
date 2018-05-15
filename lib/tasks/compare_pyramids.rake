namespace :compare do
  TAB = "\t".freeze

  def fetch_selected_orgunits(project, pyramids, selected_regions, rejected_districts)
    orgunits = Set.new
    pyramids.each do |_month, pyramid|
      contracted = pyramid.org_units_in_group(project.entity_group.external_reference)
      orgunits.merge(contracted)
    end

    orgunits = orgunits.to_a.index_by(&:id).values

    selected_orgunits = orgunits.select do |ou|
      selected_regions.any? { |selected_region| ou.path.include?(selected_region) } &&
        rejected_districts.none? { |rejected_district| ou.path.include?(rejected_district) }
    end
    selected_orgunits.sort_by(&:path)
  end

  def fetch_pyramids(project, months)
    months.each_with_object({}) do |month_period, hash|
      pyramid = project.project_anchor.nearest_pyramid_for(month_period.end_date)
      hash[month_period] = pyramid
    end
  end

  def diff_orgunit_groups(selected_orgunits, pyramids, subcontract_groupset_id)
    selected_orgunits.each do |selected_orgunit|
      results = pyramids.values.map do |pyramid|
        orgunit = pyramid.org_unit(selected_orgunit.id)
        next unless orgunit
        orgunit_group_ids = orgunit.organisation_unit_groups.map { |g| g["id"] }.sort
        orgunit_groups = pyramid.org_unit_groups(orgunit_group_ids.sort)
        parents = pyramid.org_unit_parents(orgunit.id)[1..-1]

        subcontracted_ous = pyramid.org_units_in_same_group(orgunit, subcontract_groupset_id)

        groupset_group_ids = pyramid.org_unit_group_set(subcontract_groupset_id).organisation_unit_groups.map { |e| e["id"] }
        groupet_org_unit_group_ids = orgunit.organisation_unit_groups.map { |e| e["id"] }
        common_group_ids = (groupset_group_ids & groupet_org_unit_group_ids).sort
        common_groups = pyramid.org_unit_groups(common_group_ids)
        [
          parents.map(&:name).join(" > "),
          parents.map(&:id).join(" > "),
          orgunit.name,
          orgunit_groups.compact.map(&:name).sort.join(","),
          orgunit_group_ids.join(","),
          common_group_ids.join(","),
          common_groups.map(&:name).join(","),
          subcontracted_ous.map(&:name).join(","),
          subcontracted_ous.map(&:id).join(",")
        ].join(TAB)
      end
      next unless results.uniq.size > 1

      yield(results, selected_orgunit)
    end
  end

  desc "compare pyramid snapshots"
  task pyramids: :environment do
    write = ENV.fetch("MODIFY") == "true"
    project = Project.find(9)
    quarter_periods = [Periods.from_dhis2_period("2018Q2"), Periods.from_dhis2_period("2018Q1")]
    compared_months = quarter_periods.flat_map(&:months).sort
    reference_period = Periods.from_dhis2_period("201805")
    compared_months -= [reference_period]
    selected_regions = %w[
      x0GbxmB4a0T
      BfD6kZSmKjb

      lr8un7u9V0s
      HZkms5QPpoD
      MEUzb5Br39P
      YYmAhyUwb1q
      BkqmnUS612P
      QC75ingyLVz
      vVJdgAW1rrp
      QHwsuxXIpWB
      xv7AAEZfW26
    ]
    # Est
    rejected_districts = %w[]
    subcontract_groupset_id = "pHH6kYd3i98"

    months = compared_months + [reference_period]
    pyramids = fetch_pyramids(project, months)
    selected_orgunits = fetch_selected_orgunits(project, pyramids, selected_regions, rejected_districts)
    if !write
      diff_orgunit_groups(selected_orgunits, pyramids, subcontract_groupset_id) do |results, _orgunit|
        # report to stdout diff
        months.each_with_index do |month, index|
          puts month.to_dhis2 + TAB + results[index].to_s
        end
      end
    else

      orgunits_to_fix = []

      diff_orgunit_groups(selected_orgunits, pyramids, subcontract_groupset_id) do |_results, orgunit|
        orgunits_to_fix << orgunit
      end

      compared_months.each do |month|
        puts "****** fixing #{month}"
        ou_dhis2_snapshot = project.project_anchor.dhis2_snapshots.where(kind: "organisation_units", year: month.year, month: month.month).first
        next unless ou_dhis2_snapshot
        puts "found to fix #{ou_dhis2_snapshot.id} #{ou_dhis2_snapshot.year} #{ou_dhis2_snapshot.month}"
        ou_reference_snapshot = project.project_anchor.dhis2_snapshots.where(kind: "organisation_units", year: reference_period.year, month: reference_period.month).first
        puts "found as ref #{ou_reference_snapshot.id} #{ou_reference_snapshot.year} #{ou_reference_snapshot.month}"

        group_dhis2_snapshot = project.project_anchor.dhis2_snapshots.where(kind: "organisation_unit_groups", year: month.year, month: month.month).first
        puts "found as oug_fix #{group_dhis2_snapshot.id} #{group_dhis2_snapshot.year} #{group_dhis2_snapshot.month}"

        group_reference_snapshot = project.project_anchor.dhis2_snapshots.where(kind: "organisation_unit_groups", year: reference_period.year, month: reference_period.month).first
        puts "found as oug_ref #{group_reference_snapshot.id} #{group_reference_snapshot.year} #{group_reference_snapshot.month}"

        groupset_dhis2_snapshot = project.project_anchor.dhis2_snapshots.where(kind: "organisation_unit_group_sets", year: month.year, month: month.month).first
        puts "found as ougs_fix #{groupset_dhis2_snapshot.id} #{groupset_dhis2_snapshot.year} #{groupset_dhis2_snapshot.month}"

        groupset_reference_snapshot = project.project_anchor.dhis2_snapshots.where(kind: "organisation_unit_group_sets", year: reference_period.year, month: reference_period.month).first
        puts "found as ougs_ref #{groupset_reference_snapshot.id} #{groupset_reference_snapshot.year} #{groupset_reference_snapshot.month}"

        contract_group_set_reference = groupset_reference_snapshot.content_for_id(subcontract_groupset_id)

        orgunits_to_fix.each do |orgunit|
          ou_to_fix = ou_dhis2_snapshot.content_for_id(orgunit.id)
          ou_reference = ou_reference_snapshot.content_for_id(orgunit.id)

          unless ou_to_fix
            ou_to_fix = JSON.parse(JSON.generate(ou_reference))
            ou_dhis2_snapshot.content << { "table"=> ou_to_fix }
          end
          puts "  fixing #{orgunit.id} #{orgunit.name}\n\t#{ou_to_fix['organisation_unit_groups']}\n\t#{ou_reference['organisation_unit_groups']}"
          ou_to_fix["organisation_unit_groups"] = ou_reference["organisation_unit_groups"]

          contract_group_set_to_fix = groupset_dhis2_snapshot.content_for_id(subcontract_groupset_id)

          ou_reference["organisation_unit_groups"].each do |group_added|
            puts group_added
            group_to_fix = group_dhis2_snapshot.content_for_id(group_added["id"])
            puts group_to_fix["name"] if group_to_fix
            if group_to_fix
              if group_to_fix["organisation_units"].include?("id" => orgunit.id)
                puts "group #{group_to_fix['name']} already exist and contains #{orgunit.id}"
              else
                puts "group #{group_to_fix['name']} doesn't contains #{orgunit.id}"
                group_to_fix["organisation_units"] << { "id" => orgunit.id }
              end
            else
              puts "group doesn't exist"
              group_to_add = group_reference_snapshot.content_for_id(group_added["id"])
              group_dhis2_snapshot.content << { "table"=> group_to_add }
            end

            to_check = { "id" => group_added["id"] }
            included_in_to_fix = contract_group_set_to_fix["organisation_unit_groups"].include?(to_check)
            included_in_reference = contract_group_set_reference["organisation_unit_groups"].include?(to_check)

            if included_in_reference && !included_in_to_fix
              contract_group_set_to_fix["organisation_unit_groups"] << to_check
            end
          end
        end

        # whatever remove confessional from contract groups
        confessional_id = "DMRsfc2ooGX"

        contract_group_set = groupset_dhis2_snapshot.content_for_id(subcontract_groupset_id)
        if contract_group_set["organisation_unit_groups"].include?("id" => confessional_id)
          contract_group_set["organisation_unit_groups"].delete("id" => confessional_id)
        end

        groupset_dhis2_snapshot.save!

        group_dhis2_snapshot.save!

        ou_dhis2_snapshot.save!
      end
    end
  end
end
