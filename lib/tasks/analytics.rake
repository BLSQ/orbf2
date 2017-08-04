namespace :analytics do
  desc "Run analytics on project Dhis2"
  task run: :environment do
     Dhis2AnalyticsWorker.perform_async(ENV['project_id'])
  end
end
