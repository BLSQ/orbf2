class Setup
  attr_reader :steps

  def initialize(steps)
    @steps = calculate_highlighted(steps)
  end

  def calculate_highlighted(steps)
    first_todo_step = steps.find { |step| step.status == :todo }
    steps.each do |step|
      step.highlighted = step == first_todo_step
    end
    steps
  end
end
