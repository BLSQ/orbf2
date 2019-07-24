class Setup::JobsController < PrivateController
  helper_method :jobs
  attr_reader :jobs

  class JobsSummary < Struct.new(:scheduled_jobs, :last_jobs); end

  def index
    pyramid = current_project.project_anchor.nearest_pyramid_for(DateTime.now)

    @jobs = JobsSummary.new(
      Jobs::ScheduledJobsService.new(current_project, pyramid).jobs,
      Jobs::LastJobsService.new(current_project, pyramid).jobs
    )
  end
end
