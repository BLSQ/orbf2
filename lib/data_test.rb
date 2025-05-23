# frozen_string_literal: true

require_relative "data_test/subject"
require_relative "data_test/file_helpers"
require_relative "data_test/capture"
require_relative "data_test/compare"
require_relative "data_test/verifier"
require_relative "data_test/uploader"
require_relative "data_test/fetcher"
begin
  require "aws-sdk-s3"
  require "zip"
rescue LoadError
  # We're probably in production, production should not be able to
  # upload to S3, it's allowed to load this file, but it shouldn't
  # break.
end

module DataTest
  # This module is to help get a test flow that uses actual production
  # data and verifies the result of new code.
  #
  # The main flow is to capture data `DataTest::Capture`, upload it to
  # S3 `DataTest::Uploader` so that test runs can access it using the
  # `DataTest::Fetcher` and verify the results with the
  # `DataTest::Verifier`
  #
  # Normally you should never interact with these classes but instead
  # execute:
  #
  #      # to capture (if they need to be updated due to a format change)
  #      DB_NAME=<production-copy> bundle exec rake data_test:capture_and_upload
  #
  #      # To test (also gets run by CI)
  #      bundle exec rake spec:data_test
  #
  # You'll need upload permissions on S3 to run the capture phase,
  # you'll need read-only permissions to run the fetcher. If you don't
  # have the read-only permissions, the spec will be skipped. (CI has them)
  S3_BUCKET = ENV["DATA_TEST_S3_BUCKET"]
  S3_REGION = ENV["DATA_TEST_S3_REGION"] # Frankfurt
  ARTEFACT_DIR = Rails.root.join("spec", "artefacts")
  RESULTS_DIR = Rails.root.join("tmp", "verifier")
  CONFIG_PATH = Rails.root.join("config", "data_test.json")

  class NoS3Configured < StandardError; end

  def self.can_verify?
    has_artefacts? && has_config_file?
  end

  def self.can_capture?
    has_config_file?
  end

  def self.keep_artefacts?
    ENV["KEEP_ARTEFACTS"]
  end

  # I think has_artefacts is more clear than artefacts.
  # rubocop:disable Naming/PredicateName
  def self.has_artefacts?
    Dir.glob(File.join(ARTEFACT_DIR, "*")).grep(/yml|json/).any?
  end

  def self.has_config_file?
    File.exist? CONFIG_PATH
  end
  # rubocop:enable Naming/PredicateName

  def self.clear_config_file!
    return unless has_config_file?

    File.unlink(CONFIG_PATH)
  end

  def self.clear_artefacts!
    artefact_directory = ARTEFACT_DIR
    Dir.foreach(artefact_directory) do |f|
      if f != "." && f != ".." && f != ".gitkeep"
        path = File.join(artefact_directory, f)
        File.unlink(path)
      end
    end
  end

  def self.all_cases
    return {} unless has_config_file?

    test_json  = JSON.parse(File.read(CONFIG_PATH))
    test_cases = test_json.each_with_object({}) do |(name, cases), result|
      cases.each do |v|
        subject = DataTest::Subject.new(name, v)
        result[subject.name] = subject
      end
    end
    test_cases
  end
end
