# frozen_string_literal: true

require "shellwords"
require_relative "../data_test"

namespace :data_test do
  desc "Clear all artefacts"
  task :clear_artefacts do
    puts "=> Clearing existing artefacts"
    DataTest.clear_artefacts!
  end

  desc "Run simulation and capture all artefacts"
  task capture: :environment do
    output_directory = Rails.root.join("tmp/new_artefacts")
    FileUtils.mkdir(output_directory) unless File.exist? output_directory

    puts "=> Capturing to #{output_directory}\n"
    test_cases = DataTest.all_cases
    selected_test_case_name = ENV["test_case"] || "all"

    if selected_test_case_name != "all"
      test_cases = test_cases.select { |(name, _cases)| name =~ /#{selected_test_case_name}/ }
    end

    failures = {}
    test_cases.each.with_index do |(test_case_name, subject), i|
      begin
        puts "+ #{i + 1}/#{test_cases.keys.count} #{subject.project_name} - #{subject.orgunit_ext_id}"
        DataTest::Capture.new(subject, output_directory).call
      rescue StandardError => error
        puts "  -> FAILED"
        failures[test_case_name] = error
        raise error if ENV["FAIL_FAST"]
      end
    end
    if failures.empty?
      puts "  -> Captured them all in #{output_directory}"
    else
      puts failures
      abort "Encountered failures. Stopping"
    end
  end

  desc "Quick check"
  task verify: :environment do
    puts "=> Verifying\n"
    test_cases = DataTest.all_cases
    selected_test_case_name = ENV["test_case"] || "all"

    if selected_test_case_name != "all"
      test_cases = test_cases.select { |(name, _cases)| name =~ /#{selected_test_case_name}/ }
    end
    test_cases.each.with_index do |(test_case_name, subject), i|
      begin
        puts "+ #{i + 1}/#{test_cases.keys.count} #{subject.project_name} - #{subject.orgunit_ext_id}"
        DataTest::Verifier.new(subject).call
      rescue StandardError => error
        puts "  -> FAILED"
        failures[test_case_name] = error
        raise error if ENV["FAIL_FAST"]
      end
    end
  end

  task check_upload_credentials: :environment do
    unless DataTest::Uploader.can_run?
      abort "You don't have S3 configured. Upload would fail so not even starting"
    end
  end

  task capture_and_upload: %i[check_upload_credentials clear_artefacts capture upload environment] do
    # Thanks to the magic of rake, it will now:
    # - check if you can upload
    # - clear any existing artefacts
    # - generate new artefacts
    # - zips them and uploads them to S3
    puts "All done. `latest.zip` will now be available on S3"
  end

  desc "Upload artefacts"
  task upload: :environment do
    puts "=> Uploading to S3+\n"
    uploader = DataTest::Uploader.new
    begin
      uploader.store_config_file
      uploader.store_all_artefacts
    rescue DataTest::NoS3Configured => e
      abort "S3 was not configured properly: #{e}"
    end
  end

  desc "Download artefacts"
  task download: :environment do
    fetcher = DataTest::Fetcher.new
    begin
      fetcher.fetch_all_artefacts
    rescue DataTest::NoS3Configured => e
      abort "S3 was not configured properly: #{e}"
    end
  end

  desc "Download config file"
  task download_config: :environment do
    fetcher = DataTest::Fetcher.new
    begin
      fetcher.fetch_config_file
    rescue DataTest::NoS3Configured => e
      abort "S3 was not configured properly: #{e}"
    end
  end

  desc "Upload config file"
  task upload_config: :environment do
    uploader = DataTest::Uploader.new
    begin
      puts "=> Uploading to S3"
      uploader.store_config_file
    rescue DataTest::NoS3Configured => e
      abort "S3 was not configured properly: #{e}"
    end
  end
end
