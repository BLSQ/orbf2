require "raven"

unless Rails.env.development? || Rails.env.test?
  Raven.configure do |config|
    config.dsn          = ENV["SENTRY_DSN"]
    config.environments = %w[testing staging production]
  end
end
