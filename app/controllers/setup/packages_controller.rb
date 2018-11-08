# frozen_string_literal: true

class Setup::PackagesController < PrivateController
  helper_method :package
  attr_reader :package

  def edit
    @package = current_project.packages.find(params[:id])
    render :edit
  end

  def update
    @package = current_project.packages.find(params[:id])

    package.update(params_package)

    update_package_constants

    if package.valid? && params[:package][:main_entity_groups]
      entity_groups = package.create_package_entity_groups(
        params[:package][:main_entity_groups],
        params[:package][:target_entity_groups]
      )
      package.package_entity_groups = []
      package.package_entity_groups.create(entity_groups)
      package.save!
      package.package_states.each(&:save!)
      SynchroniseDegDsWorker.perform_async(current_project.project_anchor.id)
      flash[:success] = "Package updated"
      redirect_to(root_path)
    else
      Rails.logger.info "!!!!!!!! package invalid : #{package.errors.full_messages.join(',')}"
      flash[:failure] = "Package doesn't look valid..."
      flash[:failure] += "Please select at least one organisation group" unless params[:package][:main_entity_groups]
      render :edit

    end
  end

  def new
    @package = current_project.packages.build
  end

  def create
    @package = current_project.packages.build(params_package)

    state_ids = params_package[:state_ids].reject(&:empty?)

    update_package_constants

    package.states = current_project.states.find(state_ids)

    if package.invalid?
      flash[:failure] = "Package not valid..."
      render "new"
      return
    end

    entity_groups = package.create_package_entity_groups(
      params[:package][:main_entity_groups],
      params[:package][:target_entity_groups]
    )
    package.data_element_group_ext_ref = "todo"
    if package.save

      package.package_entity_groups.create(entity_groups)
      SynchroniseDegDsWorker.perform_async(current_project.project_anchor.id)
      flash[:success] = "Package of Activities created success"
      redirect_to(root_path)
    else
      flash[:failure] = "Error creating Package of Activities"
      render "new"
    end
  end

  private

  def update_package_constants
    package.package_states.each do |package_state|
      de_external_reference = params["data_elements"][package_state.state_id.to_s] if params["data_elements"]
      package_state.de_external_reference = de_external_reference if de_external_reference
    end
  end

  def params_package
    params.require(:package).permit(
      :name, :frequency, :kind, :ogs_reference,
      state_ids: [], activity_ids: [], groupsets_ext_refs: []
    )
  end
end
