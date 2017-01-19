class Setup::SetupController < PrivateController
  helper_method :setup
  attr_reader :setup

  helper_method :project
  attr_reader :project

  def index
    current_program.build_project_anchor unless current_project_anchor
    current_program.project_anchor unless current_project
    if current_project_anchor && current_project_anchor.project
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

    step1 = Step.new(name:   "Dhis2 connection",
                     status: current_project_anchor.invalid_project? ? :todo : :done,
                     kind:   :dhis2,
                     model:  project || current_project_anchor.projects.build)

    step2 = Step.new(name:   "Entities",
                     status: step1.todo? || project.entity_group.nil? ? :todo : :done,
                     kind:   :entities,
                     model:  step1.todo? ? nil : project.entity_group || project.build_entity_group)

    step3 = Step.new(name:   "Package of Activities",
                     status: step2.todo? || project.packages.nil? || project.packages.empty? ? :todo : :done,
                     kind:   :packages,
                     model:  step1.todo? || step2.todo? ? nil : project.packages)

    step4_todo = step3.todo? || project.packages.flat_map(&:rules).empty? ||
                 project.packages.flat_map(&:rules).any?(&:invalid?) ||
                 project.packages.any? { |p| p.rules.size != 2 } ||
                 project.payment_rules.empty? ||
                 project.payment_rules.map(&:rule).any?(&:invalid?) ||
                 !project.unused_packages.empty?

    step4 =  Step.new(name:   "Rules",
                      status: step4_todo ? :todo : :done,
                      kind:   :rules,
                      model:  step3.todo? ? nil : project.packages)

    step5 =  Step.new(name:   "Incentive Configuration",
                      status: step4_todo ? :todo : :done,
                      kind:   :incentives,
                      model:  step4.todo? ? IncentiveConfig.new : IncentiveConfig.new)

    step6 = Step.new(name:   "Publish project",
                     status: step4_todo ? :todo : :done,
                     kind:   :publish,
                     model:  step4.todo? ? nil : project )
    current_project_anchor.projects.last.publish_date = Date.today.to_date.strftime("%Y-%m-%d")
    @setup = Setup.new([step1, step2, step3, step4, step5, step6])
  end
  end
