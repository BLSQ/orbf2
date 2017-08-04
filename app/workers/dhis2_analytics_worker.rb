class Dhis2AnalyticsWorker
  include Sidekiq::Worker

  def perform(project_id)
    project = Project.find(project_id)
    dhis2 = project.dhis2_connection
    dhis2.resource_tables.analytics
  end
end
