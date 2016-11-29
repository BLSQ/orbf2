class SetupController < PrivateController
  helper_method :steps
  attr_reader :steps

  def index
    @steps = [
      Step.new(name: "dhis2 connection", status: "todo"),
      Step.new(name: "Entities", status: "todo"),
      Step.new(name: "Entity group", status: "todo"),
      Step.new(name: "Package of Activities", status: "todo"),
      Step.new(name: "Rules", status: "todo"),
      Step.new(name: "Tarification plan", status: "todo")
    ]
  end
end
