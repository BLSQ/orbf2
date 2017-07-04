class Setup
  class SetupController < PrivateController
    helper_method :setup
    attr_reader :setup

    helper_method :project
    attr_reader :project

    def index
      current_program.build_project_anchor unless current_project_anchor
      @project = current_program.project_anchor.projects.build unless current_project(
        raise_if_published: false
      )

      unless params[:project_id]
        latest_draft = current_program.project_anchor.latest_draft
        redirect_to setup_project_path(latest_draft) && return if latest_draft
      end
      if current_project_anchor && current_project_anchor.project && params[:project_id]
        @project = current_project_anchor.projects.fully_loaded.find(params[:project_id])
      end
      project&.publish_date = Time.zone.today.to_date.strftime("%Y-%m-%d")
      @setup = Setup.new(Step.steps(project))
    end
  end
end
