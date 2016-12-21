class SeedsController < PrivateController
  def index
    current_user.project = ProjectFactory.new.build(dhis2_url: "http://play.dhis2.org/demo", user: "admin", password: "district", bypass_ssl: false)
    current_user.project.build_entity_group(name: "Public facilities", external_reference: "oRVt7g429ZO").save!

    hospital_group = {name: "Hospital", organisation_unit_group_ext_ref: "tDZVQ1WtwpA"}
    clinic_group = {name: "Clinic", organisation_unit_group_ext_ref: "RXL3lPSK8oG"}

    package_quantity_pma = current_user.project.packages[0]
    package_quantity_pma.states = State.where(name: %w(Claimed Verified)).to_a
    package_quantity_pma.package_entity_groups[0].update_attributes(clinic_group)
    package_quantity_pca = current_user.project.packages[1]
    package_quantity_pca.states = State.where(name: %w(Claimed Verified)).to_a
    package_quantity_pca.package_entity_groups[0].update_attributes(hospital_group)
    package_quality = current_user.project.packages[2]
    package_quality.states = State.where(name: %w(Claimed Verified)).to_a
    package_quality.package_entity_groups[0].update_attributes(clinic_group)
    package_quality.package_entity_groups[1].update_attributes(hospital_group)

    current_user.save!
    redirect_to root_path
  end
end
