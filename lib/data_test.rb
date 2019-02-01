# frozen_string_literal: true

require_relative "data_test/subject"
require_relative "data_test/file_helpers"
require_relative "data_test/capture"
require_relative "data_test/verifier"
require_relative "data_test/uploader"
require_relative "data_test/fetcher"
require "aws-sdk-s3"
require "zip"

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
  S3_BUCKET = "orbf-artefacts"
  S3_REGION = "eu-central-1" # Frankfurt
  ARTEFACT_DIR = Rails.root.join("spec", "artefacts")
  RESULTS_DIR = Rails.root.join("tmp", "verifier")

  class NoS3Configured < StandardError; end

  # I think has_artefacts is more clear than artefacts.
  # rubocop:disable Naming/PredicateName
  def self.has_artefacts?
    Dir.glob(File.join(ARTEFACT_DIR, "*")).grep(/yml|json/).any?
  end
  # rubocop:enable Naming/PredicateName

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
    test_json  = JSON.parse(File.read(Rails.root.join("config", "data_test.json")))
    test_cases = test_json.each_with_object({}) do |(name, cases), result|
      cases.each do |v|
        subject = DataTest::Subject.new(name, v)
        result[subject.name] = subject
      end
    end
    test_cases
  end
end
