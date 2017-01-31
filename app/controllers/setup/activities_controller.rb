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

        allowedstates = current_project.packages.find(params[:activity][:package_id]).state_ids

        activity = current_project.activities.build
        activity.name = params[:activity][:name]
        activity.activity_packages.build(
          package_id: params[:activity][:package_id]
        )

        data_compound = DataCompound.from(current_project)
        data_elements = params[:data_elements].map { |element_id| data_compound.data_element(element_id) }
        data_elements.each do |element|
          next unless allowedstates.include? params[:activity][:states][element.id].to_i
          activity.activity_states.build(
            name:               element.name,
            external_reference: element.id,
            state_id:           params[:activity][:states][element.id]
          )
        end
        if activity.save
          flash[:success] = "Data element created successfuly"
          redirect_to(root_path)
        else
          @activity = activity
          @packages = current_project.packages
          flash[:failure] = "Error creating activity"
          render :new
        end
      end
    end
  end

  def edit
    @activity = current_project.activities.where(id: params[:id]).first
    params[:data_elements] = @activity.activity_states.map{|activ| activ.external_reference}
    @packages = current_project.packages
    render :new
  end

  private

  def params_package
    params.require(:activity).permit(:name)
  end
end
