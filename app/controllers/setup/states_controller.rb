class Setup::StatesController < PrivateController
  helper_method :state
  attr_reader :state

  def create
    @state = current_project.states.build(state_params)
    if @state.save
      flash[:notice] = "Rule created !"
      redirect_to(root_path)
    else
      render action: "new"
    end
  end

  def new
    @state = current_project.states.build
  end

  private

  def state_params
    params.require(:state)
          .permit(:name)
  end
end
