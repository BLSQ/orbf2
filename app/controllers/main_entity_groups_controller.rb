class MainEntityGroupsController < PrivateController
  def create
    unless current_project
      flash[:alert] = "Please configure your dhis2 settings first !"
      return redirect_to(root_path)
    end

    create_or_update

    if current_project.entity_group.save
      flash[:success] = "Main entity group set !"
    else
      flash[:alert] = current_project.entity_group.errors.full_messages.join(", ")
    end

    redirect_to(root_path)
  end

  private

  def current_project
    @current_project ||= current_program.project
  end

  def create_or_update
    if current_project.entity_group
      current_project.entity_group.update_attributes(entity_group_params)
    else
      current_project.build_entity_group(entity_group_params)
    end
  end

  def entity_group_params
    params.require(:entity_group).permit(:name, :external_reference)
  end
end
