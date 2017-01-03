class SetupController < PrivateController
  helper_method :setup
  attr_reader :setup

  helper_method :project
  attr_reader :project

  def index
    @project = Project.includes(
      packages:      {
        rules:                 [formulas: [:rule]],
        package_entity_groups: [:package],
        package_states:        [:package, :state]
      },
      payment_rules: [
        rule: [
          formulas: [:rule],
          payment_rule: []
        ]
      ]
    ).find(current_user.project.id) if current_user.project

    step1 = Step.new(name:   "Dhis2 connection",
                     status: current_user.invalid_project? ? :todo : :done,
                     kind:   :dhis2,
                     model:  project || current_user.build_project)

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
                 project.payment_rules.map(&:rule).any?(&:invalid?)

    step4 =  Step.new(name:   "Rules",
                      status: step4_todo ? :todo : :done,
                      kind:   :rules,
                      model:  step3.todo? ? nil : project.packages)

    step5 =  Step.new(name:   "Incentive Configuration",
                      status: :todo,
                      kind:   :incentives,
                      model:  step4.todo? ? IncentiveConfig.new : IncentiveConfig.new)

    @setup = Setup.new([step1, step2, step3, step4, step5])
  end
end
