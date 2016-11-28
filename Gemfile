source "https://rubygems.org"

ruby "2.3.1"

gem "dhis2", github: "BLSQ/dhis2"

gem "rails", "~> 5.0.0", ">= 5.0.0.1"
gem "pg", "~> 0.18"
gem "puma", "~> 3.0"
gem "bootstrap-sass", "~> 3.3.6"
gem "sass-rails", "~> 5.0"
gem "font-awesome-sass", "~> 4.7.0"
gem "uglifier", ">= 1.3.0"
gem "coffee-rails", "~> 4.2"
gem "jquery-rails"
gem "turbolinks", "~> 5"
gem "jbuilder", "~> 2.5"
gem "devise"

group :development, :test do
  gem "byebug", platform: :mri
  gem "database_cleaner"
  gem "factory_girl_rails", " 4.0"
  gem "rspec-its"
  gem "rspec-rails", "~> 3.0"
  gem "shoulda-matchers", require: false
  gem "rest-client-logger"
end

group :development do
  gem "annotate"
  gem "web-console"
  gem "listen", "~> 3.0.5"
  gem "spring"
  gem "spring-watcher-listen", "~> 2.0.0"
  gem "rack-mini-profiler"
  gem "memory_profiler"
  gem "flamegraph"
  gem "stackprof"
end

group :test do
  gem "simplecov", require: false
  gem "codeclimate-test-reporter", "~> 1.0.0"
  gem "webmock"
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: [:mingw, :mswin, :x64_mingw, :jruby]
