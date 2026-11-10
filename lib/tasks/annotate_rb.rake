# frozen_string_literal: true

# annotate models after db:migrate in development (settings in .annotaterb.yml)
# Set ANNOTATERB_SKIP_ON_DB_TASKS to skip.
if Rails.env.development? && ENV["ANNOTATERB_SKIP_ON_DB_TASKS"].nil?
  require "annotate_rb"

  AnnotateRb::Core.load_rake_tasks
end
