class SeedsController < PrivateController
  def index
    current_user.project = ProjectFactory.new.build(
      dhis2_url:  "http://play.dhis2.org/demo",
      user:       "admin",
      password:   "district",
      bypass_ssl: false
    )
    current_user.project.build_entity_group(
      name:               "Public facilities",
      external_reference: "oRVt7g429ZO"
    )

    suffix = " - "+ Time.now.to_s[0..15]
    hospital_group = { name: "Hospital", organisation_unit_group_ext_ref: "tDZVQ1WtwpA" }
    clinic_group = { name: "Clinic", organisation_unit_group_ext_ref: "RXL3lPSK8oG" }
    default_states = State.where(name: %w(Claimed Verified)).to_a

    package_quantity_pma = current_user.project.packages[0]
    package_quantity_pma.name += suffix
    package_quantity_pma.states = default_states
    package_quantity_pma.package_entity_groups[0].update_attributes(clinic_group)

    package_quantity_pca = current_user.project.packages[1]
    package_quantity_pca.name += suffix
    package_quantity_pca.states = default_states
    package_quantity_pca.package_entity_groups[0].update_attributes(hospital_group)

    package_quality = current_user.project.packages[2]
    package_quality.name += suffix
    package_quality.states = default_states
    package_quality.package_entity_groups[0].update_attributes(clinic_group)
    package_quality.package_entity_groups[1].update_attributes(hospital_group)

    package_quantity_pca.save!
    package_quantity_pma.save!
    package_quality.save!
  

    current_user.project.save!
    current_user.save!
    flash[:notice] =" created package and rules for #{suffix} : #{package_quantity_pma.name}"
    redirect_to root_path
  end
end
