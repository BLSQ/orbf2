require_relative "boot"

require "rails"
# Pick the frameworks you want:
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
require "action_controller/railtie"
require "action_mailer/railtie"
require "action_view/railtie"
require "action_cable/engine"
require "sprockets/railtie"
require "active_storage/engine"
# require "rails/test_unit/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Scorpio
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 5.1

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.
    logger           = ActiveSupport::Logger.new(STDOUT)
    logger.formatter = config.log_formatter
    config.logger    = ActiveSupport::TaggedLogging.new(logger)
    config.log_level = ENV["LOG_LEVEL"] || :info
    config.lograge.enabled = ENV["LOGRAGE"] == "true"
    config.lograge.custom_options = lambda do |event|
      {
        exception:        event.payload[:exception], # ["ExceptionClass", "the message"]
        exception_object: event.payload[:exception_object] # the exception instance
      }
    end

    config.active_job.queue_adapter = :sidekiq
    config.assets.initialize_on_precompile = false

    # These are defined in `/lib/*.rb
    require "scorpio"
    require "parallel_dhis2"
    require "can_access_developer_tools_constraint"
    require "api_constraints"
  end
end
