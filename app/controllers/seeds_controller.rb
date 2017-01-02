class SeedsController < PrivateController
  def index
    current_user.project = ProjectFactory.new.build(
      dhis2_url:  "https://play.dhis2.org/demo",
      user:       "admin",
      password:   "district",
      bypass_ssl: false
    )
    current_user.project.build_entity_group(
      name:               "Public facilities",
      external_reference: "oRVt7g429ZO"
    )

    project = current_user.project

    suffix = " - "+ Time.now.to_s[0..15]
    hospital_group = { name: "Hospital", organisation_unit_group_ext_ref: "tDZVQ1WtwpA" }
    clinic_group = { name: "Clinic", organisation_unit_group_ext_ref: "RXL3lPSK8oG" }
    default_quantity_states = State.where(name: %w(Claimed Verified Tarif)).to_a
    default_quality_states = State.where(name: ["Claimed","Verified" ,"Max. Score"]).to_a

    project.name = "Sierra Leone"

    package_quantity_pma = project.packages[0]
    package_quantity_pma.name += suffix
    package_quantity_pma.states = default_quantity_states
    package_quantity_pma.package_entity_groups[0].update_attributes(clinic_group)
    created_ged = package_quantity_pma.create_data_element_group(["FTRrcoaog83", "P3jJH5Tu5VC", "FQ2o8UBlcrS", "M62VHgYT2n0"])
    package_quantity_pma.data_element_group_ext_ref = created_ged.id

    package_quantity_pca = project.packages[1]
    package_quantity_pca.name += suffix
    package_quantity_pca.states = default_quantity_states
    package_quantity_pca.package_entity_groups[0].update_attributes(hospital_group)
    created_ged = package_quantity_pca.create_data_element_group(["FTRrcoaog83", "P3jJH5Tu5VC", "FQ2o8UBlcrS", "M62VHgYT2n0"])
    package_quantity_pma.data_element_group_ext_ref = created_ged.id

    package_quality = project.packages[2]
    package_quality.name += suffix
    package_quality.states = default_quality_states
    package_quality.package_entity_groups[0].update_attributes(clinic_group)
    package_quality.package_entity_groups[1].update_attributes(hospital_group)
    created_ged = package_quality.create_data_element_group(["p4K11MFEWtw", "wWy5TE9cQ0V", "r6nrJANOqMw", "a0WhmKHnZ6J", "nXJJZNVAy0Y", "hnwWyM4gDSg", "CecywZWejT3", "bVkFujnp3F2"])
    package_quality.data_element_group_ext_ref = created_ged.id

    package_quantity_pca.save!
    package_quantity_pma.save!
    package_quality.save!

    current_user.project.save!
    current_user.save!
    flash[:notice] =" created package and rules for #{suffix} : #{package_quantity_pma.name}"
    redirect_to root_path
  end
end
