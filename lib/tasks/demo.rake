
namespace :demo do
  TEST_CASES = {
    cm_pma:                    {
      project_id:     "9",
      year:           "2017",
      quarter:        "4",
      orgunit_ext_id: "eov2pDYbAK0"
    },
    cm_pma_subcontract:        {
      project_id:     "9",
      year:           "2017",
      quarter:        "4",
      orgunit_ext_id: "FKwP5mdXS44"
    },
    cm_pca:                    {
      project_id:     "9",
      year:           "2017",
      quarter:        "4",
      orgunit_ext_id: "gjQVhah9fej"
    },
    cm_with_nine_subcontracts: {
      project_id:     "9",
      year:           "2017",
      quarter:        "4",
      orgunit_ext_id: "lr8un7u9V0s"
    },
    cm_bambalang:              {
      project_id:     "9",
      year:           "2017",
      quarter:        "4",
      orgunit_ext_id: "x0GbxmB4a0T"
    },
    mw_bemonc_chikuse:         {
      project_id:     "11",
      year:           "2017",
      quarter:        "1",
      orgunit_ext_id: "DsCJ5VYc6vm"
    },
    mw_bemonc_chikuse_idr:     {
      project_id:     "11",
      year:           "2015",
      quarter:        "1",
      orgunit_ext_id: "DsCJ5VYc6vm"
    },
    mw_cemonc_dedza_dh:        {
      project_id:     "11",
      year:           "2015",
      quarter:        "1",
      orgunit_ext_id: "PBqAud9Tvcc"
    },
    mw_dhmt_dedza:             {
      project_id:     "11",
      year:           "2017",
      quarter:        "1",
      orgunit_ext_id: "TiaEk64xgmm"
    }

  }.with_indifferent_access

  desc "Run invoice from commandline"
  task invoice: :environment do
    test_case_name = ENV["test_case"]
    test_case = OpenStruct.new(TEST_CASES[test_case_name])

    puts "***** #{test_case_name} : #{test_case.to_h}"

    raise " no '#{test_case_name}' only knows #{TEST_CASES.keys.join(', ')}" if test_case.to_h.empty?

    invoicing_period = "#{test_case.year}Q#{test_case.quarter}"

    project = Project.fully_loaded.find(test_case.project_id)
    data_compound = DataCompound.from(project)
    orbf_project = MapProjectToOrbfProject.new(project, data_compound.indicators).map
    fetch_and_solve = Orbf::RulesEngine::FetchAndSolve.new(orbf_project, test_case.orgunit_ext_id, invoicing_period)
    fetch_and_solve.call
    orbf_invoices = Orbf::RulesEngine::InvoicePrinter.new(fetch_and_solve.solver.variables, fetch_and_solve.solver.solution).print

    exported_values = clean_values(fetch_and_solve.exported_values)

    invoices = InvoicesForEntitiesWorker.new.perform(
      project.project_anchor_id,
      test_case.year,
      test_case.quarter,
      [test_case.orgunit_ext_id],
      publisher_ids:          [],
      mock_values:            false,
      force_project_id:       test_case.project_id,
      allow_fresh_dhis2_data: true
    )[test_case.orgunit_ext_id]

    legacy_exported_values = clean_values(Publishing::Dhis2InvoicePublisher.new.to_values(invoices))

    missing = (exported_values - legacy_exported_values)
    extra   = (legacy_exported_values - exported_values)
    puts "exported_values        #{exported_values.size} "
    puts "legacy_exported_values #{exported_values.size} "
    puts "missing                #{missing.size}"
    puts "extra                  #{extra.size}"
    puts "*************** details "
    puts "missing : #{JSON.pretty_generate(missing)}"
    puts "extra : #{JSON.pretty_generate(extra)}"

    missing_indexed = missing.group_by { |v| [v[:dataElement], v[:orgUnit], v[:period]] }
    extra_indexed = extra.group_by { |v| [v[:dataElement], v[:orgUnit], v[:period]] }

    missing_indexed.each do |k, v|
      puts "#{k.join("\t")} => #{v.first[:value]} #{extra_indexed[k]}"
    end
    puts "---------------------- project "
    # puts YAML.dump(orbf_project)

    #puts JSON.pretty_generate(fetch_and_solve.solver.build_problem)
    raise " legacy vs rules engine failed " unless missing.empty? && extra.empty?
  end

  def clean_values(values)
    values.each do |v|
      v.delete(:comment)
      v[:value] = format("%.10f", v[:value])
    end
  end
end
