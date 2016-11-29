module SetupHelper
  def step_status_icon(step)
    step.status == :todo ? "exclamation-triangle text-warning" : "check text-success"
  end
end
