# frozen_string_literal: true

module DataTest
  class Uploader
    attr_accessor :s3

    def initialize
      credentials = Aws::Credentials.new(access_key, secret)
      Aws.config.update(region:      S3_REGION,
                        credentials: credentials)
      @s3 = Aws::S3::Resource.new(region: S3_REGION)
    end

    def access_key
      ENV["ARCHIVAL_S3_ACCESS"]
    end

    def secret
      ENV["ARCHIVAL_S3_KEY"]
    end

    def can_run?
      !!access_key && !!secret
    end

    def bucket
      s3.bucket(S3_BUCKET)
    end

    def store_all_artefacts
      all_artefacts = Pathname.new(ARTEFACT_DIR).join("*").to_s
      all_paths = Dir.glob(all_artefacts).grep(/yml|json/)
      store_zip(all_paths)
    end

    def store(file_path, name: nil)
      path = Pathname.new(file_path)
      file_name = name || path.basename.to_s
      obj = bucket.object(file_name)
      obj.upload_file(path.to_s)
    rescue Aws::S3::Errors::InvalidAccessKeyId => e
      raise NoS3Configured, e.to_s
    end

    def store_zip(array_of_paths, name: "latest.zip")
      array_of_paths = Array.wrap(array_of_paths)
      zip_file = Tempfile.new("latest.zip")
      puts "  -> Zipping"
      Zip::File.open(zip_file.path, Zip::File::CREATE) do |zipfile|
        array_of_paths.each do |path|
          path = Pathname.new(path)
          zipfile.add(path.basename, path.to_s)
        end
      end
      puts "  -> Uploading"
      store(zip_file.path, name: name)
      zip_file.unlink
    end
  end
end
