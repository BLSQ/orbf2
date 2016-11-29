class SetupController < PrivateController
  helper_method :steps
  attr_reader :steps

  def index
    @steps = calculate_highlighted [
      Step.new(name: "Dhis2 connection", status: :todo, kind: :dhis2),
      Step.new(name: "Entities", status: :todo, kind: :entities),
      Step.new(name: "Entity group", status: :todo, kind: :groups),
      Step.new(name: "Package of Activities", status: :todo, kind: :packages),
      Step.new(name: "Rules", status: :todo, kind: :rules),
      Step.new(name: "Tarification plan", status: :todo, kind: :tarifications)
    ]
  end

  private

  def calculate_highlighted(steps)
    first_todo_step = steps.find { |step| step.status == :todo }
    steps.each do |step|
      step.highlighted = step.status == :todo && step != first_todo_step
    end
    steps
  end
end
