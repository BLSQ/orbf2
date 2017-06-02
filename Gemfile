source "https://rubygems.org"

ruby "2.3.1"

gem "bootstrap-datepicker-rails"
gem "bootstrap-sass", "~> 3.3.6"
gem "cocoon"
gem "coffee-rails", "~> 4.2"
gem "deep_cloneable"
gem "dentaku"
gem "devise", "~> 4.2.0"
gem "dhis2", github: "BLSQ/dhis2", branch: "feature/add-organisation-unit-group-sets"
gem "easy_diff"
gem "figaro"
gem "font-awesome-sass", "~> 4.7.0"
gem "hashdiff"
gem "jbuilder", "~> 2.5"
gem "jquery-rails"
gem "jquery-ui-rails"
gem "pg", "~> 0.18"
gem "puma", "~> 3.0"
gem "rails", "~> 5.0.0", ">= 5.0.0.1"
gem "rails-jquery-autocomplete"
gem "rails_admin"
gem "sass-rails", "~> 5.0"
gem "sidekiq"
gem "simple_form"
gem "turbolinks", "~> 5"
gem "uglifier", ">= 1.3.0"
gem "lograge"

group :development, :test do
  gem "byebug", platform: :mri
  gem "database_cleaner"
  gem "factory_girl_rails", " 4.0"
  gem "faker"
  gem "rails-controller-testing"
  gem "rest-client-logger"
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

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: [:mingw, :mswin, :x64_mingw, :jruby]
