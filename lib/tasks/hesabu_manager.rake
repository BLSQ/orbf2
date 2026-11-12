# frozen_string_literal: true

# Installs the hesabu-manager build served by Setup::HesabuManagerController.
#
#   rake hesabu_manager:install                       # latest build (public s3, overwritten by each manager deploy)
#   rake "hesabu_manager:install[https://.../Hesabu.zip]"
#   rake "hesabu_manager:install[../hesabu-manager/build]" # local build dir
namespace :hesabu_manager do
  DEFAULT_URL = "https://hesabu-manager-build.s3.amazonaws.com/Hesabu.zip"

  desc "install the hesabu-manager build in public/hesabu-manager (zip url, zip file or build dir)"
  task :install, [:source] do |_t, args|
    require "fileutils"
    require "open-uri"
    require "tmpdir"

    source = args[:source].presence || ENV["HESABU_MANAGER_BUILD"].presence || DEFAULT_URL
    target = File.expand_path("../../public/hesabu-manager", __dir__)

    Dir.mktmpdir do |tmp|
      build_dir = if File.directory?(source)
                    source
                  else
                    zip = File.join(tmp, "Hesabu.zip")
                    if source.start_with?("http")
                      URI.open(source) { |remote| File.binwrite(zip, remote.read) }
                    else
                      FileUtils.cp(source, zip)
                    end
                    system("unzip", "-q", zip, "-d", File.join(tmp, "build"), exception: true)
                    File.join(tmp, "build")
                  end
      raise "no index.html in #{source}" unless File.exist?(File.join(build_dir, "index.html"))

      FileUtils.rm_rf(target)
      FileUtils.cp_r(build_dir, target)
    end
    puts "hesabu manager installed from #{source} in #{target}"
  end
end
