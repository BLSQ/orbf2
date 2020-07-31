# frozen_string_literal: true

source "https://rubygems.org"

ruby "2.5.1"

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?("/")
  "https://github.com/#{repo_name}.git"
end

## Infrastructure

gem "dhis2", github: "BLSQ/dhis2", branch: "legacy-v2"
gem "paper_trail", "~> 10.1.0"
gem "paper_trail-association_tracking", "~> 1.0.0"
gem "pg", "~> 0.18"
gem "puma", "~> 3.12"
gem "rack", ">= 2.0.6"
gem "rails", "~> 5.2", "< 5.3"

gem "rails_admin", "~> 1.4.2"
gem "sidekiq", "< 6"
gem "sidekiq-throttled", "~> 0.9.0"

## Tooling

gem "bootsnap", "~> 1.3.2"
gem "figaro"
gem "lograge", "~> 0.10.0"
gem "sentry-raven", "~> 2.7.4"

# Feature flipper is the act of enabling/disabling features in your app...
# [flipper](https://github.com/jnunemaker/flipper)
gem "flipper", "~> 0.16.1"
gem "flipper-active_record", "~> 0.16.1"
gem "flipper-ui", "~> 0.16.1"

## Frontend and asset related

gem "bootstrap-datepicker-rails"
gem "bootstrap-sass", "~> 3.4.1"
gem "cocoon"
gem "coffee-rails", "~> 4.2"
gem "jquery-rails", "~> 4.3.3"
gem "jquery-ui-rails", "~> 5.0.5"
gem "rails-jquery-autocomplete"
gem "sassc-rails", "~> 2.0.0"
gem "simple_form"
gem "sprockets", "~> 3.7.2"
gem "turbolinks", "~> 5"
gem "uglifier", ">= 1.3.0"
# Use webpack to manage app-like JavaScript modules in Rails
# [webpacker](https://github.com/rails/webpacker)
gem "webpacker", "~> 4.0.1"

## Authentication

# Flexible authentication solution for Rails with Warden
# [devise](https://github.com/plataformatec/devise)
gem "devise", "~> 4.7.1"

# Log in as another user in Rails
# [pretender](https://github.com/ankane/pretender)
gem "pretender", "~> 0.3.4"

## API related

gem "aws-sdk-s3", "~> 1.30.1"
gem "fast_jsonapi"
gem "jbuilder", "~> 2.5"
gem "json", "2.3.0"

## Utilities

gem "deep_cloneable"
gem "differ"
gem "hashdiff"
gem "loofah", ">= 2.2.3"
gem "naturalsort"

## Formula calculation

gem "dentaku"
if ENV["ORBF_DEV_MODE"]
  gem "hesabu", path: "../hesabu"
  gem "orbf-rules_engine", path: "../orbf-rules_engine"
else
  # We're using both of them against the latest master. We should set
  # them to versions when they become more stable
  gem "hesabu", github: "BLSQ/hesabu"
  gem "orbf-rules_engine", github: "BLSQ/orbf-rules_engine", branch: "master"
end
# Like a modern code version of the mythical beast with 100 serpent hea...
# [typhoeus](https://github.com/typhoeus/typhoeus)
gem "typhoeus", "~> 1.3.1"

group :development, :test do
  gem "byebug", platform: :mri

  # Use pry instead of irb: http://pryrepl.org
  gem "pry", "~> 0.12.2"
  gem "pry-rails", "~> 0.3.9"

  gem "database_cleaner"
  gem "factory_bot_rails", "~> 4.11.1"
  gem "faker"
  gem "immigrant"
  gem "rails-controller-testing"
  gem "rest-client-logger", github: "uswitch/rest-client-logger"
  gem "rspec-its"
  gem "rspec-rails", "~> 3.0"
  gem "ruby-prof"
  gem "shoulda-matchers", require: false

  gem "capybara"
  gem "json-diff", "~> 0.4.1"
  gem "rubyzip", "~> 1.3.0"
  gem "selenium-webdriver"
end

group :development do
  gem "annotate", "~> 2.7.4"
  gem "flamegraph"
  gem "listen", "~> 3.0.5"
  gem "memory_profiler"
  gem "pronto"
  gem "pronto-flay", require: false
  gem "pronto-rubocop", require: false
  gem "pronto-simplecov", require: false
  gem "rack-mini-profiler"
  gem "rubocop", require: false
  gem 'rubocop-rails', require: false
  gem "spring"
  gem "spring-watcher-listen", "~> 2.0.0"
  gem "stackprof"
  gem "web-console"
end

group :test do
  gem "rspec-sidekiq"
  gem "simplecov", require: false
  gem "webmock"
end

group :production do
  gem "heroku-deflater"
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: %i[mingw mswin x64_mingw jruby]
