class Setup::ActivitiesController < PrivateController
  def new
    @activity = current_project.activities.build
  end

  def create
    @activity = current_project.activities.build

    data_compound = DataCompound.from(current_project)
    data_elements = params[:data_elements].map { |element_id| data_compound.data_element(element_id) }

    data_elements.each do |element|
      @activity.activity_states.build(
        external_reference: element.external_reference,
        name: element.name
      )
    end

    render :new
   end

  private

  def params_package
    params.require(:activity).permit(:name)
  end
end
