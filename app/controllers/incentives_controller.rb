class IncentivesController < PrivateController
  helper_method :incentive
  attr_reader :incentive

  def new
    @incentive = IncentiveConfig.new
    @incentive.state = State.configurables.first.id
    @incentive.package = current_user.project.packages.first.id
    @incentive.start_date = Date.today.to_date.beginning_of_month
    @incentive.end_date = Date.today.to_date.end_of_month
    @project = current_user.project
  end

  def create
    @incentive = IncentiveConfig.new(incentive_params)
    @project = current_user.project
    @incentive.package = @project.packages.find(@incentive.package) if @incentive.package.present?
    @incentive.state = @incentive.package.find(@incentive.state) if @incentive.state.present? && @incentive.package.present?

    if @incentive.valid?
      if @incentive.activity_incentives.empty?
        @incentive.activity_incentives = @incentive.package.fetch_activities.map do |activity|
          ActivityIncentive.new(
            activity: activity,
            value:    0.0
          )
        end
        render "new"
      else
        create_data_element_group_for_incentive(@incentive)
    end
    else
      # puts @incentive.errors.full_messages
      # raise @incentive.errors.full_messages
      render "new"
    end
  end

  def update; end

  def incentive_params
    params.require(:incentive_config)
          .permit(:package,
                  :state,
                  :start_date,
                  :end_date,
                  entity_groups: [])
  end

  def create_data_elements_for_incentive(incentive)
    dhis2 = project.dhis2_connection
    data_elements = dhis2.data_elements.list(fields: "id,displayName,code", page_size: 20_000)
    data_elements_by_code = data_elements.group_by(&:code)
    data_elements_for_state = incentive.activity_incentives.map do |ai|
      {
        name:         "#{incentive.state.name} for #{ai.activity.name}",
        display_name: "#{incentive.state.name} for #{ai.activity.name}",
        code:         "#{incentive.state.name} for #{ai.activity.external_reference}",
        short_name:   "#{incentive.state.name} for #{ai.activity.external_reference}"[0..49]
      }
    end

    data_elements_for_state.each do |de_for_state|
      existing_elements = data_elements_by_code[de_for_state.code]
      de_for_state[:id] = existing_elements.first.id unless existing_elements.empty?
    end
    dhis2.data_elements.create(data_elements_for_state.select { |e| e[:id].nil? })

    data_elements = dhis2.data_elements.list(fields: "id,displayName,code", page_size: 20_000)
    data_elements_by_code = data_elements.group_by(&:code)

    data_elements_for_state.each do |de_for_state|
      existing_elements = data_elements_by_code[de_for_state.code]
      de_for_state[:id] = existing_elements.first.id unless existing_elements.empty?
    end

    data_elements_for_state
  end

  def create_data_element_group_for_incentive(incentive)
    deg_name = "#{incentive.state.name} for #{incentive.package.name}"
    deg = [
      { name:          deg_name,
        short_name:    deg_name[0..49],
        code:          deg_name[0..49],
        display_name:  deg_name,
        data_elements: data_element_ids.map do |data_element_id|
          { id: data_element_id }
        end }
    ]
    dhis2 = project.dhis2_connection
    dhis2.data_element_groups.create(deg)
    dhis2.data_element_groups.find_by(name: name)
  end
end
