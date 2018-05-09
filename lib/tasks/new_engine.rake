namespace :new_engine do
  TEST_CASES = JSON.parse(File.read("./lib/tasks/test_cases.json"))

  desc "Run invoice from commandline"
  task invoice: :environment do
    require "colorized_string"

    test_cases = TEST_CASES.map { |k, v| [k, OpenStruct.new(v)] }
    selected_test_case_name = ENV["test_case"]

    if selected_test_case_name != "all"
      test_cases = {
        selected_test_case_name => TEST_CASES[selected_test_case_name]
      }
    end

    failures = []
    test_cases.each do |test_case_name, test_case|
      begin
        run_test_case(test_case_name, OpenStruct.new(test_case))
      rescue StandardError => e
        puts ColorizedString[" error !!!!!!!!!!!! "].colorize(:red)
        puts e.message
        failures.push e
      end
    end

    puts failures
    raise "errors encountered " if failures.any?
  end

  def run_legacy_test_case(project_anchor_id, test_case)
    with_benchmark "legacy engine" do
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
  end

  def run_new_test_case(_project_anchor_id, test_case)
    with_benchmark "new engine" do
      invoicing_period = "#{test_case.year}Q#{test_case.quarter}"

      project = Project.fully_loaded.find(test_case.project_id)
      data_compound = DataCompound.from(project)
      orbf_project = MapProjectToOrbfProject.new(project, data_compound.indicators).map
      invoicing_request = InvoicingRequest.new(entity:  test_case.orgunit_ext_id,
                                               year:    test_case.year,
                                               quarter: test_case.quarter)
      options = Invoicing::InvoicingOptions.new(
        publish_to_dhis2: false,
        force_project_id: test_case.project_id
      )

      invoice_entity = Invoicing::InvoiceEntity.new(project.project_anchor, invoicing_request, options)
      invoice_entity.call
      clean_values(invoice_entity.fetch_and_solve.exported_values)
    end
  end

  def determine_success!(legacy_exported_values, exported_values)
    raw_legacy_exported_values = JSON.parse(legacy_exported_values.to_json)
    legacy_exported_values = clean_values(legacy_exported_values)
    missing = (exported_values - legacy_exported_values)
    extra   = (legacy_exported_values - exported_values)

    missing_indexed = missing.group_by { |v| [v[:dataElement], v[:orgUnit], v[:period]] }
    extra_indexed = extra.group_by { |v| [v[:dataElement], v[:orgUnit], v[:period]] }

    with_comments = raw_legacy_exported_values.group_by do |v|
      [v["dataElement"], v["orgUnit"], v["period"]]
    end

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

    raise " legacy vs rules engine failed " unless success
  end

  def run_test_case(test_case_name, test_case)
    puts ColorizedString["***** #{test_case_name} : #{test_case.to_h}"].colorize(:light_cyan)
    raise " no '#{test_case_name}' try all or #{TEST_CASES.keys.join(', ')}" if test_case.to_h.empty?

    project_anchor_id = Project.find(test_case.project_id).project_anchor_id

    exported_values = run_new_test_case(project_anchor_id, test_case)
    legacy_exported_values = run_legacy_test_case(project_anchor_id, test_case)

    determine_success!(legacy_exported_values, exported_values)
  end

  # rubocop:disable Rails/TimeZone
  def with_benchmark(message)
    start = Time.now
    value = nil
    begin
      value = yield
    ensure
      elapsed_time = Time.now - start
      puts "   #{message} #{elapsed_time} #{value.size if value}"
    end
    value
  end
  # rubocop:enable Rails/TimeZone

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
