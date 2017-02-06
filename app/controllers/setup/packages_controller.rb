class Setup::PackagesController < PrivateController
  helper_method :package
  attr_reader :package

  def edit
    @package = current_project.packages.find(params[:id])
    render :edit
  end

  def update
    @package = current_project.packages.find(params[:id])
    package.update_attributes(params_package)

    if package.valid?
      entity_groups = package.create_package_entity_groups(params[:package][:entity_groups])
      package.package_entity_groups=[]
      package.package_entity_groups.create(entity_groups)

      package.save!
      flash[:success] = "Package updated"
      redirect_to(root_path)
    else
      puts "!!!!!!!! package invalid : #{package.errors.full_messages.join(',')}"
      flash[:failure] = "Package doesn't look valid..."
      render :edit

    end
  end

  def new
    @package = current_project.packages.build
  end

  def create
    @package = current_project.packages.build(params_package)

    state_ids = params_package[:state_ids].reject(&:empty?)

    package.states = State.find(state_ids)

    if package.invalid?
      flash[:failure] = "Package not valid..."
      render "new"
      return
    end

    entity_groups = package.create_package_entity_groups(params[:package][:entity_groups])

    package.data_element_group_ext_ref = "todo"
    if package.save

      package.package_entity_groups.create(entity_groups)

      flash[:success] = "Package of Activities created success"
      redirect_to(root_path)
    else
      flash[:failure] = "Error creating Package of Activities"
      render "new"
    end
  end

  private

  def params_package
    params.require(:package).permit(:name, :frequency, state_ids: [], activity_ids: [])
  end
end
