class Setup::ActivitiesController < PrivateController
  def new
    @activity = current_project.activities.build
  end

  def create; end

  private

  def params_package
    params.require(:activity).permit(:name)
  end
end
