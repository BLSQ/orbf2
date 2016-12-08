class PackagesController < PrivateController
  helper_method :package
  attr_reader :package

  def new
    @package = current_user.project.packages.build
  end

  def create
    @package = current_user.project.packages.build(params_package)
    if package.invalid?
      flash[:failure] = "Package not valid..."
      render "new"
      return
    end

    created_ged = package.create_data_element_group(params[:data_elements])

    if created_ged
      package.data_element_group_ext_ref = created_ged.id
      if package.save
        flash[:success] = "Package of Activities created success"
        redirect_to(root_path)
      else
        flash[:failure] = "Error creating Package of Activities"
        render "new"
      end
    else
      flash[:failure] = "Could't be create Data element group"
      render "new"
    end
  end

  private

  def params_package
    params.require(:package).permit(:name, :frequency)
  end
end
