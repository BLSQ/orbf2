# frozen_string_literal: true

require "shellwords"
require_relative "../data_test"

def ask_for_confirmation(message)
  puts message
  puts "Are you sure? y/N"
  input = STDIN.gets.chomp
  input == "y"
end

def find_test_cases
  test_cases = DataTest.all_cases
  if test_cases.empty?
    abort <<~MSG
      Error: No test cases!
      
      No test cases found, do you have a config/data_test.json?
      
      Get one using bundle exec rake data_test:download
    MSG
  end

  selected_test_case_name = ENV["TEST_CASE"] || "all"
  if selected_test_case_name != "all"
    wanted_cases = selected_test_case_name.split(",")
    test_cases = test_cases.select do |(name, _cases)|
      wanted_cases.any? { |w| name =~ /#{w}/ }
    end
  end
  test_cases
end

namespace :data_test do
  desc "Clear all artefacts"
  task :clear_artefacts do
    puts "=> Clearing existing artefacts"
    DataTest.clear_artefacts!
  end

  desc "Compare your capture against known artefacts"
  task compare_capture: :environment do
    new_directory = Rails.root.join("tmp/new_artefacts")
    test_cases = find_test_cases
    test_cases.each.with_index do |(test_case_name, subject), i|
      begin
        puts "+ #{i + 1}/#{test_cases.keys.count} #{subject.project_name} - #{subject.orgunit_ext_id}"
        DataTest::Compare.new(subject, new_directory).call
      rescue StandardError => error
        puts "  -> FAILED"
        failures[test_case_name] = error
        raise error if ENV["FAIL_FAST"]
      end
    end
  end

  desc "Run simulation and capture all artefacts"
  task capture: :environment do
    output_directory = Rails.root.join("tmp/new_artefacts")
    FileUtils.mkdir(output_directory) unless File.exist? output_directory

    puts "=> Capturing to #{output_directory}\n"
    test_cases = find_test_cases

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
    test_cases = find_test_cases

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

  desc "Upload artefacts"
  task upload: :environment do
    message = <<~STR
      Did you run?
      
      1. bundle exec rake data_test:capture
      2. bundle exec rake data_test:compare_capture
      3. Verified these results?
      4. Copied the files to the spec/artefacts folder? (these will be uploaded)
    STR
    if ask_for_confirmation(message)
      puts "=> Uploading to S3+\n"
      uploader = DataTest::Uploader.new
      begin
        uploader.store_config_file
        uploader.store_all_artefacts
      rescue DataTest::NoS3Configured => e
        abort "S3 was not configured properly: #{e}"
      end
    end
  end

  desc "Download artefacts"
  task download: :environment do
    fetcher = DataTest::Fetcher.new
    begin
      fetcher.fetch_config_file
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
