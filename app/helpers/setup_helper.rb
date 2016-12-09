module SetupHelper
  def step_status_icon(step)
    step.todo? ? "exclamation-triangle text-warning fa-lg" : "check text-success fa-lg"
  end
end
