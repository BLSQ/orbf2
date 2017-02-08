class Setup::ActivitiesController < PrivateController
  helper_method :states, :activity

  attr_reader :activity, :states

  def new
    @activity = current_project.activities.build
  end

  def create
    @states = State.where(level: "activity")
    @packages = current_project.packages
    @activity = current_project.activities.build(params_activity)
    handle_action(:new)
  end

  def edit
    @states = State.where(level: "activity")
    @packages = current_project.packages
    @activity = current_project.activities.find(params[:id])
    render(:edit)
  end

  def update
    @states = State.where(level: "activity")
    @packages = current_project.packages
    @activity = current_project.activities.find(params[:id])
    @activity.update_attributes(params_activity)
    handle_action(:edit)
  end


  def mass_creation
    @missing_activity_states = current_project.missing_activity_states
    render :mass_creation
  end

  def confirm_mass_creation
    CreateMissingDhis2ElementsWorker.perform_async(current_project.project_anchor.id)
    flash[:notice] = "creation of missing dhis2 and activity states scheduled."
    redirect_to(root_path)
  end

  private

  def handle_action(template)
    if params[:commit] && params[:commit].starts_with?("Add data elements")
      data_compound = DataCompound.from(current_project)
      existing_element_ids = @activity.activity_states.map(&:external_reference)
      selectable_element_ids = params[:data_elements] - existing_element_ids
      data_elements = selectable_element_ids.map { |element_id| data_compound.data_element(element_id) }

      data_elements.each do |element|
        @activity.activity_states.build(
          external_reference: element.id,
          name:               element.name
        )
      end
      flash[:notice] = "Assign states to desired data elements "
      render template
    elsif @activity.invalid?
      flash[:failure] = "Some validation errors occured"
      render template
    else
      id = @activity.id
      @activity.save!
      SynchroniseDegDsWorker.perform_async(current_project.project_anchor.id)
      flash[:success] = "Activity #{activity.name} #{id ? 'created' : 'updated'} !"
      redirect_to(root_path)
    end
  end

  def params_activity
    params.require(:activity).permit(
      :name,
      activity_states_attributes: [
        :id,
        :state_id,
        :name,
        :external_reference,
        :_destroy
      ]
    )
  end
end
