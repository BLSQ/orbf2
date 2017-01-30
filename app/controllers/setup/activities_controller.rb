class Setup::ActivitiesController < PrivateController
  def new
    @activity = current_project.activities.build
  end

  def create
    if !params[:activity].key?(:states)
      @activity = current_project.activities.build

      data_compound = DataCompound.from(current_project)
      data_elements = params[:data_elements].map { |element_id| data_compound.data_element(element_id) }

      data_elements.each do |element|
        @activity.activity_states.build(
          external_reference: element.external_reference.nil? ? element.id : element.external_reference,
          name:               element.name
        )
      end

      @packages = current_project.packages
      render :new
    elsif params[:activity].key?(:states)
      if params[:activity][:package_id].empty? || (params[:activity][:states].size != params[:data_elements].size)
        @activity = current_project.activities.build
        @packages = current_project.packages
        # @activity.activity_states = params[:activity][:states]
        flash[:failure] = "Please select or create a package or/and check if you selected a state for each data element"
        render :new
      else

        # save activity
        activity = Activity.new
        activity.name = params[:activity][:name]
        activity.project = current_project
        activity.save
        activity_id = activity.id

        # attach activity to package
        activity_packages = ActivityPackage.new
        activity_packages.activity_id = activity_id
        activity_packages.package_id = params[:activity][:package_id]
        activity_packages.save

        # save activities and
        data_compound = DataCompound.from(current_project)
        data_elements = params[:data_elements].map { |element_id| data_compound.data_element(element_id) }
        data_elements.each do |element|
          activity_states = ActivityState.new
          activity_states.external_reference = element.id
          activity_states.name = element.name
          # check if state is allowed in the package
          activity_states.state_id = params[:activity][:states][element.id]
          activity_states.activity_id = activity.id
          activity_states.save
        end

        flash[:success] = "Data element created successfuly"
        redirect_to(root_path)
      end
    end
  end

  private

  def params_package
    params.require(:activity).permit(:name)
  end
end
