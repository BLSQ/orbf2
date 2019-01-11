# frozen_string_literal: true

class Setup::ActivitiesController < PrivateController
  helper_method :states, :activity
  attr_reader :activity, :states

  def new
    @states = activity_level_states
    @activity = current_project.activities.build
  end

  def create
    @states = activity_level_states
    @activity = current_project.activities.build(params_activity)
    handle_action(:new)
  end

  def edit
    @states = activity_level_states
    @activity = current_project.activities.find(params[:id])
    render(:edit)
  end

  def update
    @states = activity_level_states
    @activity = current_project.activities.find(params[:id])
    @activity.update(params_activity)
    handle_action(:edit)
  end

  def mass_creation
    @missing_activity_states = current_project.missing_activity_states
    if params[:activity_id]
      @missing_activity_states = @missing_activity_states.select do |k, _v|
        k.id == params[:activity_id].to_i
      end.to_h
    end
    render :mass_creation
  end

  def confirm_mass_creation
    CreateMissingDhis2ElementForActivityWorker.perform_async(
      current_project.id,
      "activity_id"  => current_project.activities.find(params[:activity_id]).id,
      "state_id"     => current_project.states.find(params[:state_id]).id,
      "data_element" => {
        "name"       => params[:name],
        "short_name" => params[:short_name],
        "code"       => params[:code]
      }
    )
    render partial: "create_data_element"
  end

  private

  def activity_level_states
    current_project.states.where(level: "activity")
  end

  def handle_action(template)
    if params["state-mapping-action"] == "data_element" && params[:data_elements]
      Activities::AddToActivityStates.new(
        project:  current_project,
        activity: activity,
        elements: params[:data_elements],
        kind:     "data_element"
      ).call
      flash[:notice] = "Assign states to desired data elements "
    elsif params["state-mapping-action"] == "data_element_coc" && params[:data_element_cocs]
      Activities::AddToActivityStates.new(
        project:  current_project,
        activity: activity,
        elements: params[:data_element_cocs],
        kind:     "data_element_coc"
      ).call
    elsif params["state-mapping-action"] == "indicator" && params[:indicators]
      Activities::AddToActivityStates.new(
        project:  current_project,
        activity: activity,
        elements: params[:indicators],
        kind:     "indicator"
      ).call
    elsif @activity.invalid?
      flash[:failure] = "Some validation errors occured"
      Rails.logger.info "invalid activity #{@activity.errors.full_messages}"
    else
      id = @activity.id
      @activity.save!
      SynchroniseDegDsWorker.perform_async(current_project.project_anchor.id)
      flash[:success] = "Activity #{activity.name} #{id ? 'created' : 'updated'} !"
    end

    render template
  end

  def params_activity
    params.require(:activity).permit(
      :name,
      :short_name,
      :code,
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
