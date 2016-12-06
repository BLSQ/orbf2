class PackagesController < PrivateController
  helper_method :package
  attr_reader :package

  def new
    @package = current_user.project.packages.build
  end

  def create
    @package = current_user.project.packages.build(params_package)
    if @package.save
      redirect_to(root_path)
    else
      render "new"
    end
  end

  private

  def params_package
    params.require(:package).permit(:name, :data_element_group_ext_ref, :frequency)
  end
end
