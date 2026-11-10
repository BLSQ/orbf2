# frozen_string_literal: true

if ENV["SENTRY_DSN"] && !(Rails.env.development? || Rails.env.test?)
  Sentry.init do |config|
    config.dsn = ENV["SENTRY_DSN"]
    config.enabled_environments = %w[testing staging production dev]
    config.breadcrumbs_logger = %i[active_support_logger http_logger]
  end
end
