
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
    },
    zim_co_ma_chibuwe_clinic:  {
      project_id:     "12",
      year:           "2018",
      quarter:        "1",
      orgunit_ext_id: "moQZ9tvpYvt"
    }

  }.with_indifferent_access

  desc "Run invoice from commandline"
  task invoice: :environment do
    require "colorized_string"

    test_cases = TEST_CASES.map { |k, v| [k, OpenStruct.new(v)] }
    test_case_name = ENV["test_case"]
    test_case = OpenStruct.new(TEST_CASES[test_case_name])
    test_cases = { test_case_name.to_sym => TEST_CASES[test_case_name] } if test_case_name != "all"

    test_cases.each do |test_case_name, test_case|
      run_test_case(test_case_name, OpenStruct.new(test_case))
    end
  end

  def run_test_case(test_case_name, test_case)
    puts ColorizedString["***** #{test_case_name} : #{test_case.to_h}"].colorize(:light_cyan)
    raise " no '#{test_case_name}' only knows #{TEST_CASES.keys.join(', ')}" if test_case.to_h.empty?

    invoicing_period = "#{test_case.year}Q#{test_case.quarter}"

    project_anchor_id = Project.find(test_case.project_id).project_anchor_id

    legacy_exported_values = with_benchmark "legacy engine" do
      invoices = without_stdout do
        InvoicesForEntitiesWorker.new.perform(
          project_anchor_id,
          test_case.year,
          test_case.quarter,
          [test_case.orgunit_ext_id],
          publisher_ids:          [],
          mock_values:            false,
          force_project_id:       test_case.project_id,
          allow_fresh_dhis2_data: true
        )[test_case.orgunit_ext_id]
      end

      Publishing::Dhis2InvoicePublisher.new.to_values(invoices)
    end

    exported_values = with_benchmark "new engine" do
      project = Project.fully_loaded.find(test_case.project_id)
      data_compound = DataCompound.from(project)
      orbf_project = MapProjectToOrbfProject.new(project, data_compound.indicators).map
      fetch_and_solve = Orbf::RulesEngine::FetchAndSolve.new(orbf_project, test_case.orgunit_ext_id, invoicing_period)
      fetch_and_solve.call
      orbf_invoices = Orbf::RulesEngine::InvoicePrinter.new(fetch_and_solve.solver.variables, fetch_and_solve.solver.solution).print
      clean_values(fetch_and_solve.exported_values)
    end

    raw_legacy_exported_values = JSON.parse(legacy_exported_values.to_json)
    legacy_exported_values = clean_values(legacy_exported_values)
    missing = (exported_values - legacy_exported_values)
    extra   = (legacy_exported_values - exported_values)

    missing_indexed = missing.group_by { |v| [v[:dataElement], v[:orgUnit], v[:period]] }
    extra_indexed = extra.group_by { |v| [v[:dataElement], v[:orgUnit], v[:period]] }

    with_comments = raw_legacy_exported_values.group_by { |v| [v["dataElement"], v["orgUnit"], v["period"]] }

    success = missing.empty? && extra.empty?
    if success
      puts ColorizedString[" Success ;) "].colorize(:light_green)
      puts [
        "  exported_values        #{exported_values.size} ",
        "  legacy_exported_values #{exported_values.size} "
      ].join("\n")
    else
      puts ColorizedString[" Failure !!!!!!!!!!!! "].colorize(:red)
      puts [
        "exported_values        #{exported_values.size} ",
        "legacy_exported_values #{exported_values.size} ",
        "missing                #{missing.size}",
        "extra                  #{extra.size}",
        "*************** details ",
        "missing : #{JSON.pretty_generate(missing)}",
        "extra : #{JSON.pretty_generate(extra)}"
      ].join("\n")
      missing_indexed.each do |k, v|
        comment = with_comments[k]
        puts "#{k.join("\t")} => #{v.first[:value]}\t#{extra_indexed[k].first[:value]}\t#{comment.first['comment']}"
      end
  end

    # puts YAML.dump(orbf_project)

    # puts JSON.pretty_generate(fetch_and_solve.solver.build_problem)
    raise " legacy vs rules engine failed " unless success
  end

  def with_benchmark(message)
    start = Time.now
    value = nil
    begin
      value = yield
    ensure
      elapsed_time = Time.now - start
      puts "   #{message} #{elapsed_time}"
    end
    value
    end

  def without_stdout
    original_stderr = $stderr
    original_stdout = $stdout
    original_level = Rails.logger.level
    Rails.logger.level = :error
    results = nil
    begin
      $stderr = File.open(File::NULL, "w")
      $stdout = File.open(File::NULL, "w")
      results = yield
    ensure
      $stderr = original_stderr
      $stdout = original_stdout
      Rails.logger.level = original_level
    end
    results
  end

  def clean_values(values)
    values.each do |v|
      v.delete(:comment)
      v[:value] = format("%.10f", v[:value])
    end
  end
end
