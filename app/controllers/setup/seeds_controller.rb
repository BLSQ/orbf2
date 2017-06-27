class Setup::SeedsController < PrivateController
  def index
    current_user.program.create_project_anchor unless current_user.program.project_anchor
    project = ProjectFactory.new.build(
      dhis2_url:      params[:local] ? "http://127.0.0.1:8085/" : "https://play.dhis2.org/demo",
      user:           "admin",
      password:       "district",
      bypass_ssl:     false,
      project_anchor: current_user.program.project_anchor
    )

    current_user.program.project_anchor.projects.destroy_all
    current_user.program.project_anchor.projects.push project

    project.build_entity_group(
      name:               "Public facilities",
      external_reference: "oRVt7g429ZO"
    )

    suffix = " - " + Time.now.to_s[0..15]
    hospital_group = { name: "Hospital",       organisation_unit_group_ext_ref: "tDZVQ1WtwpA" }
    clinic_group = {   name: "Clinic",         organisation_unit_group_ext_ref: "RXL3lPSK8oG" }
    admin_group = {    name: "Administrative", organisation_unit_group_ext_ref: "w0gFTTmsUcF" }
    default_quantity_states = State.where(name: %w[Claimed Verified Tarif]).to_a
    default_quality_states = State.where(name: ["Claimed", "Verified", "Max. Score"]).to_a
    default_performance_states = State.where(name: ["Claimed", "Max. Score", "Budget"]).to_a

    project.name = "Sierra Leone"

    update_package_with_dhis2(
      project.packages[0], suffix, default_quantity_states,
      [clinic_group],
      %w[FTRrcoaog83 P3jJH5Tu5VC FQ2o8UBlcrS M62VHgYT2n0]
    )
    update_package_with_dhis2(
      project.packages[1], suffix, default_quantity_states,
      [hospital_group],
      %w[FTRrcoaog83 P3jJH5Tu5VC FQ2o8UBlcrS M62VHgYT2n0]
    )
    update_package_with_dhis2(
      project.packages[2], suffix, default_quality_states,
      [clinic_group, hospital_group],
      %w[p4K11MFEWtw wWy5TE9cQ0V r6nrJANOqMw a0WhmKHnZ6J nXJJZNVAy0Y hnwWyM4gDSg CecywZWejT3 bVkFujnp3F2]
    )

    update_package_with_dhis2(
      project.packages[3], suffix, default_performance_states,
      [admin_group],
      %w[p4K11MFEWtw wWy5TE9cQ0V r6nrJANOqMw a0WhmKHnZ6J nXJJZNVAy0Y hnwWyM4gDSg CecywZWejT3 bVkFujnp3F2]
    )

    project.packages.each(&:save!)
    project.project_anchor.save!
    project.save!
    current_user.save!
    flash[:notice] = " created package and rules for #{suffix} : #{project.packages.map(&:name).join(', ')}"
    redirect_to root_path
  end

  def update_package_with_dhis2(package, suffix, states, groups, acitivity_ids)
    package.name += suffix
    package.states = states
    groups.each_with_index do |group, index|
      package.package_entity_groups[index].update_attributes(group)
    end
    created_ged = package.create_data_element_group(acitivity_ids)
    package.data_element_group_ext_ref = created_ged.id
  end
end
