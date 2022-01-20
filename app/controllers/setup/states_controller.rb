class Setup::StatesController < PrivateController
  helper_method :state
  attr_reader :state

  def new
    @state = current_project.states.build
  end

  def create
    @state = current_project.states.build(state_params)
    if @state.save
      flash[:notice] = "State created !"
      redirect_to(root_path)
    else
      render action: "new"
    end
  end

  def edit
    @state = current_project.states.find(params[:id])
    @has_packages = @state.has_packages
    render :edit
  end

  def update
    @state = current_project.states.find(params[:id])
    state.update(state_params)
    if state.valid?
      state.save!
      flash[:success] = "State updated"
      redirect_to(root_path)
    else
      Rails.logger.info "!!!!!!!! state invalid : #{state.errors.full_messages.join(',')}"
      flash[:failure] = "State doesn't look valid..."
      render :edit
    end
  end

  def destroy
    @state = current_project.states.find(params[:id])
    if @state.has_packages
      flash[:failure] = "State is in use"
    else
      flash[:success] = "State deleted"
      @state.destroy
    end
    redirect_to(root_path)
  end 

  private

  def state_params
    params.require(:state).permit(:name, :short_name)
  end
end
