class IncentiveConfig
  include ActiveModel::Model
  attr_accessor :id, :state_id, :package_id, :state, :package, :entity_groups, :activity_incentives, :start_date, :end_date, :project, :entities

  validates :package, presence: true
  validates :state, presence: true
  validate :validates_state_belong_to_package
  validates :entity_groups, length: { minimum: 1, message: "You need to select at least one group" }
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

  def start_date_as_date
    Date.parse("#{start_date}-01")
  end

  def end_date_as_date
    Date.parse("#{end_date}-01").end_of_month
  end

  def validates_state_belong_to_package
    errors.add(:state_id, "#{state.name} is not associated to selected package. #{package.name} has #{package.states.select(&:configurable).map(&:name).join(', ')} states") unless package.states.include? state
  end

  def find_or_create_activity_incentives
    package_des = get_data_elements_by_package
    state_created_des = create_data_elements_for_state(package_des)
    state_created_deg = create_data_element_group(state_created_des)
    existing_values = get_data_elements_values(state_created_deg)

    existing_values_by_element_id = existing_values.group_by(&:data_element)

    self.activity_incentives = state_created_des.map do |de|
      values = existing_values_by_element_id[de.id]
      value = if values
                values.map(&:value).uniq.size == 1 ? values.first.value : nil
              end
      ActivityIncentive.new(
        name:               de.name,
        external_reference: de.id,
        value:              value
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
    dhis2.data_elements.create(
      package_des.map do |de|
        {
          code:         "#{state.code}-#{de[:id]}",
          short_name:   "#{state.name} for #{de[:name]}"[0..49],
          name:         "#{state.name} for #{de[:name]}",
          display_name: "#{state.name} for #{de[:name]}"
        }
      end
    )
    package_des.map do |de|
      dhis2.data_elements.find_by(code: "#{state.code}-#{de[:id]}")
    end
  end

  def create_data_element_group(state_created_des)
    deg_code = "#{state.code}-#{package.name}"
    deg_name = "#{state.name} for #{package.name}"
    deg = [
      { name:          deg_name,
        short_name:    deg_name[0..49],
        code:          deg_code,
        display_name:  deg_name,
        data_elements: state_created_des.map do |state_created_de|
          { id: state_created_de.id }
        end }
    ]
    dhis2 = project.dhis2_connection
    dhis2.data_element_groups.create(deg)
    dhis2.data_element_groups.find_by(code: deg_code)
  end

  def set_data_elemets_values
    period = start_date

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

  def get_data_elements_values(deg)
    dhis2 = project.dhis2_connection
    values_query = {
      organisation_unit_group: entity_groups.first,
      data_element_groups:     [deg.id],
      start_date:              start_date_as_date,
      end_date:                end_date_as_date
    }
    values = dhis2.data_value_sets.list(values_query)
    values.table ? existing_values.values : []
  rescue RestClient::ExceptionWithResponse => e
    puts "Failed to access data element values #{values_query.to_json} #{e.message} #{e.response.body} #{e.response.request.url.gsub(project.password, '[REDACTED]')}"
    []
  end
end
