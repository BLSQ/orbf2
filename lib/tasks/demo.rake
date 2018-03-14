
namespace :demo do
  TEST_CASES = {
    mw_pma:             {
      project_id:     "9",
      year:           "2017",
      quarter:        "4",
      orgunit_ext_id: "eov2pDYbAK0"
    },
    mw_pma_subcontract: {
      project_id:     "9",
      year:           "2017",
      quarter:        "4",
      orgunit_ext_id: "FKwP5mdXS44"
    },
    mw_pca:             {
      project_id:     "9",
      year:           "2017",
      quarter:        "4",
      orgunit_ext_id: "gjQVhah9fej"
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
    orbf_project = MapProjectToOrbfProject.new(project).map
    exported_values = clean_values(Orbf::RulesEngine::FetchAndSolve.new(orbf_project, test_case.orgunit_ext_id, invoicing_period).call)

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
    puts "missing #{missing.size}"
    puts "extra   #{extra.size}"
    raise " legacy vs rules engine failed " unless missing.empty? && extra.empty?
  end

  def clean_values(values)
    values.each do |v|
      v.delete(:comment)
      v[:value] = format("%.10f", v[:value])
    end
  end
end
