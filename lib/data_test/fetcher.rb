# frozen_string_literal: true

module DataTest
  class Fetcher
    attr_accessor :s3

    def initialize
      credentials = Aws::Credentials.new(access_key, secret)
      Aws.config.update(region:      S3_REGION,
                        credentials: credentials)
      @s3 = Aws::S3::Resource.new(region: S3_REGION)
    end

    def access_key
      ENV["ARCHIVAL_S3_ACCESS"] || ENV["FETCHER_S3_ACCESS"]
    end

    def secret
      ENV["ARCHIVAL_S3_KEY"] || ENV["FETCHER_S3_KEY"]
    end

    def can_run?
      !!access_key && !!secret && !!S3_REGION
    end

    def self.can_run?
      return false unless !!S3_REGION
      new.can_run?
    end

    def bucket
      s3.bucket(S3_BUCKET)
    end

    def fetch_all_artefacts
      get_and_extract_zip(ARTEFACT_DIR)
    end

    def get(name, output_path)
      obj = bucket.object(name)
      obj.get(response_target: output_path)
    rescue Aws::S3::Errors::InvalidAccessKeyId => e
      raise NoS3Configured, e.to_s
    end

    def get_and_extract_zip(output_directory, name: "latest.zip")
      DataTest.clear_artefacts!
      output_file = Tempfile.new("latest.zip")
      get(name, output_file.path)
      Zip::File.open(output_file.path) do |zip_file|
        zip_file.each do |entry|
          output_path = File.join(output_directory, entry.name)
          puts "  -> Extracting #{entry.name}"
          entry.extract(output_path)
        end
      end
      output_file.unlink
    end
  end
end
