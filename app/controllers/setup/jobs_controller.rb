class Setup::JobsController < PrivateController
  helper_method :jobs
  attr_reader :jobs

  class JobsSummary
    attr_reader :scheduled_jobs, :last_jobs
    def initialize(scheduled_jobs:, last_jobs:)
      @scheduled_jobs = scheduled_jobs
      @last_jobs = last_jobs
    end
  end

  def index
    pyramid = current_project.project_anchor.nearest_pyramid_for(Date.new)

    @jobs = JobsSummary.new(
      scheduled_jobs: Jobs::ScheduledJobsService.new(current_project, pyramid).jobs,
      last_jobs:      Jobs::LastJobsService.new(current_project, pyramid).jobs
    )
  end
end
