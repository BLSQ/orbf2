class SetupController < PrivateController
  helper_method :setup
  attr_reader :setup

  def index
    step1 = Step.new(name:   "Dhis2 connection",
                     status: current_user.invalid_project? ? :todo : :done,
                     kind:   :dhis2,
                     model:  current_user.project || current_user.build_project)

    step2 = Step.new(name:   "Entities",
                     status: step1.todo? || current_user.project.entity_group.nil? ? :todo : :done,
                     kind:   :entities,
                     model:  step1.todo? ? nil : current_user.project.entity_group || current_user.project.build_entity_group)

    step3 = Step.new(name:   "Package of Activities",
                     status: step2.todo? || current_user.project.packages.nil? || current_user.project.packages.empty? ? :todo : :done,
                     kind:   :packages,
                     model:  step1.todo? || step2.todo? ? nil : current_user.project.packages)

    step4 =  Step.new(name:   "Rules",
                      status: step3.todo? || current_user.project.packages.flat_map(&:rules).empty? || current_user.project.packages.flat_map(&:rules).any? {|r| r.invalid? } ? :todo : :done,
                      kind:   :rules,
                      model:  step3.todo? ? nil : current_user.project.packages)

    step5 =  Step.new(name: "Tarification plan", status: :todo, kind: :tarifications)

    @setup = Setup.new([step1, step2, step3, step4, step5])
  end
end
