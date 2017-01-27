class Setup::ActivitiesController < PrivateController
  def new; end

  def create; end

  private

  def params_package
    params.require(:activity).permit(:name)
  end
end
