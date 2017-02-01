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
        @project = current_project_anchor.projects.includes(
          packages:      {
            rules:                 [formulas: [:rule]],
            package_entity_groups: [:package],
            package_states:        [:package, :state]
          },
          payment_rules: [
            rule: [
              formulas:     [:rule],
              payment_rule: []
            ]
          ]
        ).find(params[:project_id])
      end

      step_connection = Step.connection(current_project_anchor)

      step_entities = Step.entities(project, step_connection)

      step_activities = Step.activities(project, step_entities)

      step_packages = Step.packages(project, step_activities, step_connection)

      step_rules = Step.rules(project, step_packages)

      step_incentives = Step.incentives(project, step_packages, step_rules)

      step_publish = Step.publish(project, step_packages)

      project&.publish_date = Time.zone.today.to_date.strftime("%Y-%m-%d")
      @setup = Setup.new([step_connection,
                          step_entities,
                          step_activities,
                          step_packages,
                          step_rules,
                          step_incentives,
                          step_publish])
    end
  end
end
