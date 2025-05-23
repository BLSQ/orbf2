class Step
  include ActiveModel::Model
  attr_accessor(:name, :status, :hint, :kind, :highlighted, :model)

  def self.steps(project)
    step_connection = connection(project.project_anchor)
    step_entities = entities(project, step_connection)
    step_states = states(project, step_entities)
    step_activities = activities(project, step_states)
    step_packages = packages(project, step_activities, step_connection)
    step_rules = rules(project, step_packages)
    step_invoicing = invoicing(project, step_packages, step_rules)
    step_publish = publish(project, step_packages)

    [step_connection,
     step_entities,
     step_states,
     step_activities,
     step_packages,
     step_rules,
     step_invoicing,
     step_publish].compact
  end

  def self.connection(current_project_anchor)
    Step.new(name:   "Dhis2 connection & Signalitic",
             status: current_project_anchor.invalid_project? ? :todo : :done,
             kind:   :dhis2,
             model:  current_project_anchor.projects.find_by(status: "draft") ||
             current_project_anchor.projects.build)
  end

  def self.entities(project, step_connection)
    Step.new(name:   "Entities",
             status: step_connection.todo? || project.entity_group.nil? ? :todo : :done,
             kind:   :entities,
             model:  step_connection.todo? ? nil : project.entity_group || project.build_entity_group)
  end

  def self.states(project, step_entities)
    Step.new(name:   "States",
             status: step_entities.todo? || project.states.empty? ? :todo : :done,
             kind:   :states,
             model:  project)
  end

  def self.activities(project, step_states)
    Step.new(name:   "Activities",
             status: step_states.todo? || project.activities.empty? ? :todo : :done,
             kind:   :activities,
             model:  step_states.todo? ? nil : project.activities)
  end

  def self.packages(project, step_activities, step_connection)
    Step.new(name:   "Package of Activities",
             status: step_activities.todo? || project.packages.nil? || project.packages.empty? ? :todo : :done,
             kind:   :packages,
             model:  step_connection.todo? || step_activities.todo? ? nil : project.packages)
  end

  def self.rules(project, step_package)
    step_rules_todo = rules_todo(project, step_package)
    Step.new(name:   "Rules",
             status: step_rules_todo ? :todo : :done,
             kind:   :rules,
             model:  step_package.todo? ? nil : project.packages)
  end

  def self.invoicing(project, step_package, _step_rules)
    step_rules_todo = rules_todo(project, step_package)
    Step.new(name:   "Invoicing",
             status: step_rules_todo ? :todo : :done,
             kind:   :invoicing,
             model:  project)
  end

  def self.publish(project, step_package)
    step_rules_todo_basic = rules_todo_basic(project, step_package)
    Step.new(name:   "Publish project",
             status: step_rules_todo_basic ? :todo : :done,
             kind:   :publish,
             model:  step_rules_todo_basic ? nil : project)
  end

  def todo?
    status == :todo
  end

  def done?
    status == :done
  end

  def self.rules_todo_basic(project, step_package)
    step_package.todo? || project.packages.flat_map(&:rules).empty? ||
      project.packages.flat_map(&:rules).any?(&:invalid?) ||
      project.payment_rules.empty? ||
      project.payment_rules.map(&:rule).any?(&:invalid?)
  end

  def self.rules_todo(project, step_package)
    rules_todo_basic(project, step_package) || !project.unused_packages.empty? ||
      project.packages.any? { |p| p.rules.size != 2 }
  end
end
