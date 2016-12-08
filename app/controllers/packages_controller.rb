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

    deg = [
      { name:          package.name,
        short_name:    package.name[0..49],
        code:          package.name[0..49],
        display_name:  package.name,
        data_elements: params[:data_elements].map do |element_id|
          { id: element_id }
        end }
    ]
    dhis2 = current_user.project.dhis2_connection
    dhis2.data_element_groups.create(deg)
    created_ged = dhis2.data_element_groups.find_by(name: params[:package][:name])
    if created_ged
      package.data_element_group_ext_ref = created_ged.id
      if package.save
        flash[:notice] = "Package of Activities created success"
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
