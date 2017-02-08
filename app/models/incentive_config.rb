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
    pyramid = Pyramid.from(project)

    self.entities = pyramid.org_units_in_all_groups(entity_groups).to_a
    org_unit_ids = entities.map(&:id)

    existing_values = []
    org_unit_ids.each_slice(100).each do |org_unit_slice_ids|
      puts "***************** fetching #{org_unit_slice_ids}"
      slice_values = get_data_elements_values_by_data_set(package.package_state(state).ds_external_reference, org_unit_slice_ids)
      puts " retrieved : #{slice_values.size}"
      existing_values.push(slice_values)
    end

    existing_values = existing_values.flatten
    existing_values_by_element_id = existing_values.group_by(&:data_element)

    self.activity_incentives = package.activity_states(state).map do |activity_state|
      values = existing_values_by_element_id[activity_state.external_reference]
      value = if values
                uniq_values = values.map(&:value).uniq
                uniq_values.size == 1 ? values.first.value : nil
              end
      ActivityIncentive.new(
        name:               activity_state.name,
        external_reference: activity_state.external_reference,
        value:              value
      )
    end
  end

  def set_data_elements_values
    period = start_date
    pyramid = Pyramid.from(project)

    self.entities = pyramid.org_units_in_all_groups(entity_groups).to_a
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

  def get_data_elements_values_by_data_set(dataset_id, org_unit_ids)
    dhis2 = project.dhis2_connection
    values_query = {
      organisation_unit: org_unit_ids,
      data_sets:         [dataset_id],
      start_date:        start_date_as_date,
      end_date:          end_date_as_date
    }
    values = dhis2.data_value_sets.list(values_query)
    values.data_values ? values.values : []
  rescue RestClient::ExceptionWithResponse => e
    raise "Failed to access data element values #{values_query.to_json} #{e.message} #{e.response.body} #{e.response.request.url.gsub(project.password, '[REDACTED]')}"
  end
end
