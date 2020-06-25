# frozen_string_literal: true

class Setup::MainEntityGroupsController < PrivateController
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

  def create_or_update
    eg_params = entity_group_params
    if entity_group_params[:external_reference].present?
      orgunitgroup = current_project.dhis2_connection.organisation_unit_groups.find(entity_group_params[:external_reference])
      eg_params = eg_params.merge(name: orgunitgroup.display_name) if orgunitgroup
    end

    if current_project.entity_group
      current_project.entity_group.update(eg_params)
    else
      current_project.build_entity_group(eg_params)
    end
  end

  def entity_group_params
    params.require(:entity_group).permit(
      :name,
      :kind,
      :external_reference,
      :limit_snaphot_to_active_regions,
      :program_reference,
      :all_event_sql_view_reference,
      :group_synchronisation_enabled,
      :contract_delay_in_months
    )
  end
end
