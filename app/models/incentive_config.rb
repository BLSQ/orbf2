class IncentiveConfig
  include ActiveModel::Model
  attr_accessor :id, :state_id, :package_id, :state, :package, :entity_groups, :activity_incentives, :start_date, :end_date, :project, :entities

  validates :package, presence: true
  validates :state, presence: true
  validate :validates_state_belong_to_package
  # validates :entity_groups, presence: true
  validates :start_date, presence: true
  validates :end_date, presence: true

  def initialize(attributes = {})
    super
    self.entity_groups = attributes[:entity_groups] unless attributes.nil?
    self.activity_incentives = attributes[:activity_incentives] if attributes && attributes[:activity_incentives]
  end

  def activity_incentives_attributes=(activity_incentives_attributes)
    self.activity_incentives = []
    activity_incentives_attributes.values.each do |att|
      activity_incentives.push ActivityIncentive.new(att)
    end
  end

  def validates_state_belong_to_package
    errors.add(:state_id, "#{state.name} is not associated to selected package. #{package.name} has #{package.states.map(&:name).join(', ')} states") unless package.states.include? state
  end

  def find_or_create_activity_incentives
    # get the de of my package
    package_des = get_data_elements_by_package
    # create the data elements
    state_created_des = create_data_elements_for_state(package_des)
    # create the deg and add data elements to the deg
    state_created_deg = create_data_element_group(state_created_des)
    # load them for value config inputs
    self.activity_incentives = state_created_des.map do |de|
      ActivityIncentive.new(
        name:               de.name,
        external_reference: de.id,
        value:              0.0
      )
    end
  end

  def get_data_elements_by_package
    # https://play.dhis2.org/demo/api/dataElements.json?filter=dataElementGroups.id:in:[HeAnxDMyrOd]
    dhis2 = project.dhis2_connection
    des = dhis2.data_elements.list(filter: "dataElementGroups.id:eq:#{package.data_element_group_ext_ref}")

    des.map do |de|
      {
        id:   de.id,
        name: de.display_name
      }
    end
  end

  def create_data_elements_for_state(package_des)
    state_created_des = []
    dhis2 = project.dhis2_connection
    # default_combo_id = dhis2.category_combos.list(fields: "id", filter: "name=default").first.id
    package_des.each do |de|
      de_to_create = [{
        code:         "#{state.code}-#{de[:id]}",
        short_name:   "#{state.name} for #{de[:name]}"[0..49],
        name:         "#{state.name} for #{de[:name]}",
        display_name: "#{state.name} for #{de[:name]}"
      }]

      dhis2.data_elements.create(de_to_create)
      # query the created indic by name or by code if you want
      state_created_de = dhis2.data_elements.find_by(code: "#{state.code}-#{de[:id]}")
      state_created_des.push state_created_de
    end
    # return the ids of the created DEs
    state_created_des
  end

  def create_data_element_group(state_created_des)
    deg_name = "#{state.code}-#{package.name}"
    deg = [
      { name:          deg_name,
        short_name:    deg_name[0..49],
        code:          deg_name[0..49],
        display_name:  deg_name,
        data_elements: state_created_des.map do |state_created_de|
          { id: state_created_de.id }
        end }
    ]
    dhis2 = project.dhis2_connection
    dhis2.data_element_groups.create(deg)
    dhis2.data_element_groups.find_by(name: deg_name)
  end

  def set_data_elemets_values
    period = start_date.split("-")
    period.pop
    period = period.map(&:to_s).join("")

    values = []
    entities.each do |org_unit|
      activity_incentives.each do |activity_incentive|
        de_values = {
          value:        activity_incentive.value,
          period:       period,
          org_unit:     org_unit.id,
          data_element: activity_incentive.external_reference
        }
        values.push de_values
      end
    end
    dhis2 = project.dhis2_connection
    dhis2.data_value_sets.create(values)
  end
end
