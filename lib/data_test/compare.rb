# frozen_string_literal: true

module DataTest
  class Compare
    include FileHelpers

    attr_accessor :subject

    class Result
      attr_accessor :short, :key_count, :full, :message

      def initialize(success:, message: "", short: [], key_count: 0, full: [])
        @success = success
        @message = message
        @short = short
        @key_count = key_count
        @full = full
      end

      def success?
        !!@success
      end

      def ok_message
        ["\033[1;32mok\033[0m", message].compact.join(" ")
      end

      def fail_message
        "\033[1;31mNot OK\033[0m"
      end
    end

    def initialize(subject, new_directory, original_directory = ARTEFACT_DIR)
      @subject = subject
      @new_directory = new_directory
      @original_directory = original_directory
    end

    def filenames_for(filename)
      file_a = File.join(@original_directory, filename)
      file_b = File.join(@new_directory, filename)
      [file_a, file_b]
    end

    def file_not_found_result
      Result.new(success: true, message: "NEW FILE")
    end

    def simple_diff(filename)
      file_a, file_b = filenames_for(filename)
      return file_not_found_result unless File.exist?(file_a)
      result = `diff -q #{file_a} #{file_b}`

      Result.new(success: result.strip.empty?, message: result.strip)
    end

    def json_diff(filename)
      file_a, file_b = filenames_for(filename)
      return file_not_found_result unless File.exist?(file_a)
      a = JSON.parse(File.open(file_a).read)
      b = JSON.parse(File.open(file_b).read)
      result = JsonDiff.diff(a, b, include_was: true)
      if result.empty?
        Result.new(success: true)
      else
        Result.new(success: false, key_count: [a.keys.count, b.keys.count], short: result.sample(10), full: result)
      end
    end

    def hash_diff(filename)
      file_a, file_b = filenames_for(filename)
      return file_not_found_result unless File.exist?(file_a)
      a = JSON.parse(File.open(file_a).read)
      b = JSON.parse(File.open(file_b).read)
      diff = HashDiff.diff(a, b, use_lcs: false)
      if diff.empty?
        Result.new(success: true)
      else
        Result.new(success: false, key_count: [a.count, b.count], short: diff.sample(10), full: diff)
      end
    end

    def handle_simple_diff(name, result)
      print "  \033[1m#{name}\033[0m"
      if result.success?
        puts "    #{result.ok_message}"
      else
        puts "    #{result.fail_message}"
        puts "    File change #{result.short}"
      end
    end

    def handle_json_diff(name, result)
      print "  \033[1m#{name}\033[0m"
      if result.success?
        puts "    #{result.ok_message}"
      else
        puts "    #{result.fail_message}"
        puts "    + Differences (first 10 out of #{result.full.count})"
        result.short.each do |item|
          puts "      [%s] Was: %s Is: %s Path: %s" % [item["op"], item["was"], item["value"], item["path"]]
        end
      end
    end

    def handle_hash_diff(name, result)
      print "  \033[1m#{name}\033[0m"
      if result.success?
        puts "    #{result.ok_message}"
      else
        puts "    #{result.fail_message}"
        puts "    + Differences (first 10 out of #{result.full.count})"
        result.short.each do |arr|
          puts "      [%s] Was: %s Is: %s Path: %s" % [arr[0], arr[2], arr[3], arr[1]]
        end
      end
    end

    def call
      puts " [input files]"
      filename = subject.filename("input-values", "json")
      handle_hash_diff(filename, hash_diff(filename))
      [
        ["project", "yml"],
        ["data-compound", "yml"],
        ["pyramid", "yml"]
      ].each do |(name, extension)|
        filename = subject.filename(name, extension)
        result = simple_diff(filename)
        handle_simple_diff(filename, result)
      end

      puts " [result files]"
      [
        ["problem", "json"],
        ["solution", "json"]
      ].each do |(name, extension)|
        filename = subject.filename(name, extension)
        result = json_diff(filename)
        handle_json_diff(filename, result)
      end

      filename = subject.filename("exported_values", "json")
      handle_hash_diff(filename, hash_diff(filename))
    end
  end
end
