# frozen_string_literal: true

module DataTest
  module FileHelpers
    # artefacts are serialized ruby objects: psych 4 (ruby >= 3.1) refuses them in load_file
    def read_yaml(file_path)
      YAML.respond_to?(:unsafe_load_file) ? YAML.unsafe_load_file(file_path) : YAML.load_file(file_path)
    end

    def record_yaml(file_path, yamlable)
      puts "  -> Writing #{file_path}"
      File.open(file_path, "w") do |f|
        f.write yamlable.to_yaml
      end
    end

    def read_json(file_path)
      JSON.parse(File.read(file_path))
    rescue StandardError
      raise "Could not read #{file_path}"
    end

    def record_json(file_path, jsonable)
      puts "  -> Writing #{file_path}"
      File.open(file_path, "w") do |f|
        f.write jsonable.to_json
      end
    end
  end
end
