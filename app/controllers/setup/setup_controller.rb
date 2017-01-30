class Setup::SetupController < PrivateController
  helper_method :setup
  attr_reader :setup

  helper_method :project
  attr_reader :project

  def index
    current_program.build_project_anchor unless current_project_anchor
    @project = current_program.project_anchor.projects.build unless current_project(raise_if_published: false)

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

    step_connection = Step.new(name:   "Dhis2 connection",
                               status: current_project_anchor.invalid_project? ? :todo : :done,
                               kind:   :dhis2,
                               model:  project || current_project_anchor.projects.build)

    step_entities = Step.new(name:   "Entities",
                             status: step_connection.todo? || project.entity_group.nil? ? :todo : :done,
                             kind:   :entities,
                             model:  step_connection.todo? ? nil : project.entity_group || project.build_entity_group)

    step_activities = Step.new(name:   "Activities",
                               status: step_entities.todo? || project.activities.empty? ? :todo : :done,
                               kind:   :activities,
                               model:  step_entities.todo? ? nil : project.activities)

    step_package = Step.new(name:   "Package of Activities",
                            status: step_activities.todo? || project.packages.nil? || project.packages.empty? ? :todo : :done,
                            kind:   :packages,
                            model:  step_connection.todo? || step_activities.todo? ? nil : project.packages)

    step_rules_todo_basic = step_package.todo? || project.packages.flat_map(&:rules).empty? ||
                            project.packages.flat_map(&:rules).any?(&:invalid?) ||
                            project.payment_rules.empty? ||
                            project.payment_rules.map(&:rule).any?(&:invalid?)

    step_rules_todo = step_rules_todo_basic || !project.unused_packages.empty? || project.packages.any? { |p| p.rules.size != 2 }

    step_rules = Step.new(name:   "Rules",
                          status: step_rules_todo ? :todo : :done,
                          kind:   :rules,
                          model:  step_package.todo? ? nil : project.packages)

    step_incentives = Step.new(name:   "Incentive Configuration",
                               status: step_rules_todo ? :todo : :done,
                               kind:   :incentives,
                               model:  step_rules.todo? ? IncentiveConfig.new : IncentiveConfig.new)

    step_publish = Step.new(name:   "Publish project",
                            status: step_rules_todo_basic ? :todo : :done,
                            kind:   :publish,
                            model:  step_rules_todo_basic ? nil : project)
    project&.publish_date = Date.today.to_date.strftime("%Y-%m-%d")
    @setup = Setup.new([step_connection, step_entities, step_activities, step_package, step_rules, step_incentives, step_publish])
  end
  end
