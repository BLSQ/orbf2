module Support
  module Profiling
    # This uses backticks to figure out the pagesize, but only once
    # when loading this module.
    # You might want to move this into some kind of initializer
    # that is loaded when your app starts and not when autoload
    # loads this module.
    KERNEL_PAGE_SIZE = `getconf PAGESIZE`.chomp.to_i

    STATM_PATH       = "/proc/#{Process.pid}/statm".freeze
    STATM_FOUND      = File.exist?(STATM_PATH)

    def self.rss
      STATM_FOUND ? (File.read(STATM_PATH).split(" ")[1].to_i * KERNEL_PAGE_SIZE) / 1024 : 0
    end

    def profile(message, &block)
      start = Time.now.utc
      element = yield block
      elapsed = Time.now.utc - start
      puts "\t => #{message} in #{elapsed}\t|\t#{Profiling.rss}"
      element
    end
  end
end
