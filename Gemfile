source "https://rubygems.org"

ruby "2.5.1"

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?("/")
  "https://github.com/#{repo_name}.git"
end

gem "bootstrap-datepicker-rails"
gem "bootstrap-sass", "~> 3.3.6"
gem "cocoon"
gem "coffee-rails", "~> 4.2"
gem "deep_cloneable"
gem "dentaku"
gem "devise", "~> 4.4.0"
gem "dhis2", github: "BLSQ/dhis2", branch: "legacy-v2"
gem "differ"
gem "easy_diff"
gem "fast_jsonapi"
gem "figaro"
gem "font-awesome-sass", "~> 4.7.0"
gem "hashdiff"

gem "jbuilder", "~> 2.5"
gem "jquery-rails"
gem "jquery-ui-rails"
gem "json", "2.1.0"
gem "lograge"
gem "loofah", ">= 2.2.3"
gem "naturalsort"
if ENV["ORBF_DEV_MODE"]
  gem "hesabu", path: "../hesabu"
  gem "orbf-rules_engine", path: "../orbf-rules_engine"
else
  gem "hesabu"
  gem "orbf-rules_engine", github: "BLSQ/orbf-rules_engine"
end
gem "paper_trail"
gem "paper_trail-association_tracking", "~> 1.0.0"

gem "pg", "~> 0.18"
gem "puma", "~> 3.0"
gem "rack", ">= 2.0.6"
gem "rails", "~> 5.1", "< 5.2"
gem "rails-jquery-autocomplete"
gem "rails_admin", "~> 1.3.0"
gem "sassc-rails", "~> 2.0.0"
gem "sentry-raven", "2.6.3"
gem "sidekiq"
gem "sidekiq-throttled"
gem "simple_form"
gem "sprockets", "~> 3.7.2"
gem "turbolinks", "~> 5"
gem "uglifier", ">= 1.3.0"

group :development, :test do
  gem "byebug", platform: :mri
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
end

group :development do
  gem "annotate"
  gem "flamegraph"
  gem "listen", "~> 3.0.5"
  gem "memory_profiler"
  gem "pronto"
  gem "pronto-flay", require: false
  gem "pronto-rubocop", require: false
  gem "pronto-simplecov", require: false
  gem "rack-mini-profiler"
  gem "rubocop", require: false
  gem "spring"
  gem "spring-watcher-listen", "~> 2.0.0"
  gem "stackprof"
  gem "web-console"
end

group :test do
  gem "codeclimate-test-reporter", "~> 1.0.0"
  gem "rspec-sidekiq"
  gem "simplecov", require: false
  gem "webmock"
end

group :production do
  gem "heroku-deflater"
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: %i[mingw mswin x64_mingw jruby]
