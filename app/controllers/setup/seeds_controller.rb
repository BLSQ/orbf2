class Setup::SeedsController < PrivateController
  def index
    current_user.program.create_project_anchor unless current_user.program.project_anchor
    project_factory = ProjectFactory.new
    suffix = " - " + Time.now.to_s[0..15]
    project = ProjectFactory.new.build(
      dhis2_url:      params[:local] ? "http://127.0.0.1:8085/" : "https://play.dhis2.org/demo",
      user:           "admin",
      password:       "district",
      bypass_ssl:     false,
      project_anchor: current_user.program.project_anchor
    )
    project_factory.update_links(project, suffix)

    current_user.program.project_anchor.projects.destroy_all
    current_user.program.project_anchor.projects.push project

    project.save!
    current_user.save!
    flash[:notice] = " created package and rules for #{suffix} : #{project.packages.map(&:name).join(', ')}"
    redirect_to root_path
  end

  def update_package_with_dhis2(package, suffix, states, groups, acitivity_ids)
    package.name += suffix
    package.states = states
    groups.each_with_index do |group, index|
      peg = package.package_entity_groups[index]
      group.each do |k, v|
        peg[k] = v
      end
    end
    created_ged = package.create_data_element_group(acitivity_ids)
    package.data_element_group_ext_ref = created_ged.id
  end
end
