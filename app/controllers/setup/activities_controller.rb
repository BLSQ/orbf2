class Setup::ActivitiesController < PrivateController
  helper_method :states, :activity
  attr_reader :activity, :states

  def new
    @activity = current_project.activities.build
  end

  def create
    @states = current_project.states.where(level: "activity")
    @activity = current_project.activities.build(params_activity)
    handle_action(:new)
  end

  def edit
    @states = current_project.states.where(level: "activity")
    @activity = current_project.activities.find(params[:id])
    render(:edit)
  end

  def update
    @states = current_project.states.where(level: "activity")
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
          name:               element.name,
          kind:               "data_element"
        )
      end
      flash[:notice] = "Assign states to desired data elements "
      render template
    elsif params[:commit] && params[:commit].starts_with?("Add indicators")
      data_compound = DataCompound.from(current_project)
      existing_element_ids = @activity.activity_states.map(&:external_reference)
      selectable_element_ids = params[:indicators] - existing_element_ids
      data_elements = selectable_element_ids.map { |element_id| data_compound.indicator(element_id) }

      data_elements.each do |element|
        @activity.activity_states.build(
          external_reference: element.id,
          name:               element.name,
          kind:               "indicator"
        )
      end
      flash[:notice] = "Assign states to desired indicators"
      render template
    elsif @activity.invalid?
      flash[:failure] = "Some validation errors occured"
      puts "invalid activity #{@activity.errors.full_messages}"
      render template
    else
      id = @activity.id
      @activity.save!
      SynchroniseDegDsWorker.perform_async(current_project.project_anchor.id)
      flash[:success] = "Activity #{activity.name} #{id ? 'created' : 'updated'} !"
      render template
    end
  end

  def params_activity
    params.require(:activity).permit(
      :name,
      activity_states_attributes: %i[
        id
        state_id
        name
        external_reference
        kind
        formula
        _destroy
      ]
    )
  end
end
