class IncentivesController < PrivateController
  helper_method :incentive
  attr_reader :incentive

  def new
    @incentive = IncentiveConfig.new
    @incentive.state = State.configurables(true).first.id
    @incentive.package = current_user.project.packages.first.id
    @incentive.start_date = Date.today.to_date.beginning_of_month
    @incentive.end_date = Date.today.to_date.end_of_month
    @project = current_user.project
    @incentive.project = @project
  end

  def create
    @incentive = IncentiveConfig.new(incentive_params)
    @project = current_user.project
    @incentive.package = @project.packages.find(@incentive.package) if @incentive.package.present?
    @incentive.state = State.find(@incentive.state) if @incentive.state.present?
    @incentive.project = current_user.project

    puts "I am going to check"

    if @incentive.valid?
      if @incentive.activity_incentives
        # save values and redirect_to setup... with a log of IncentiveConfigs
        puts "I am valid"
      else

        # get the de of my package
        package_des = get_data_elements_by_package(@incentive.package.data_element_group_ext_ref)
        # create the data elements
        state_created_des = create_data_elements_for_state(package_des, @incentive.state.name)
        # create the deg and add data elements to the deg
        state_created_deg = create_data_element_group_for_incentive(state_created_des, @incentive)
        # load them for value config inputs
        @incentive.activity_incentives = state_created_des.map do |de|
          ActivityIncentive.new(
            name:               de.name,
            external_reference: de.id,
            value:              0.0
          )
        end
        @incentive.state = @incentive.state.id
        @incentive.package = @incentive.package.id
        render "new"
      end
    end
  end

  def update; end

  def incentive_params
    params.require(:incentive_config)
          .permit(:state,
                  :package,
                  :start_date,
                  :end_date,
                  entity_groups:                  [],
                  activity_incentives_attributes: [:activity, :value, :name, :external_reference])
  end

  def create_data_elements(_de_titles)
    dhis2 = incentive.project.dhis2_connection
    data_elements = dhis2.data_elements.list(fields: "id,displayName,code", page_size: 20_000)
    data_elements_by_code = data_elements.group_by { |de| de["code"] }
    data_elements_for_state = incentive.activity_incentives.map do |ai|
      {
        name:         "RBF #{incentive.state.name} for #{ai.activity.name}",
        display_name: "RBF #{incentive.state.name} for #{ai.activity.name}",
        code:         "#{incentive.state.name.underscore}-#{ai.activity.external_reference}",
        short_name:   "RBF #{incentive.state.name} for #{ai.activity.external_reference}"[0..49]
      }
    end

    data_elements_for_state.each do |de_for_state|
      existing_elements = data_elements_by_code[de_for_state[:code]]
      de_for_state[:id] = existing_elements.first.id if existing_elements
    end
    to_create = data_elements_for_state.select { |e| e[:id].nil? }
    unless to_create.empty?
      dhis2_status = dhis2.data_elements.create(to_create)
      puts "returned #{dhis2_status.to_json} when creating #{to_create} "

      data_elements = dhis2.data_elements.list(fields: "id,displayName,code", page_size: 20_000)
      data_elements_by_code = data_elements.group_by { |de| de["code"] }
    end
    data_elements_by_name = data_elements.group_by { |de| de["name"] }

    data_elements_for_state.each do |de_for_state|
      existing_elements = data_elements_by_code[de_for_state[:code]]
      de_for_state[:id] = existing_elements.first.id if existing_elements
    end

    incentive.activity_incentives.each do |ai|
      code = "#{incentive.state.name.underscore}-#{ai.activity.external_reference}" # TODO: find a better way instead of copy paste
      name =   "RBF #{incentive.state.name} for #{ai.activity.name}"
      existing = data_elements_by_code[code]
      existing ||= data_elements_by_name[name]
      raise "no dataelement for #{ai.to_json} and #{code}" unless existing
      ai.data_element_ext_ref = existing.first["id"]
    end
    puts incentive.activity_incentives.to_json
  end

  def get_data_elements_by_package(package_ext_ref)
    # https://play.dhis2.org/demo/api/dataElements.json?filter=dataElementGroups.id:in:[HeAnxDMyrOd]
    dhis2 = incentive.project.dhis2_connection
    des = dhis2.data_elements.list(filter: "dataElementGroups.id:eq:#{package_ext_ref}")

    des.map do |de|
      {
        id:   de.id,
        name: de.display_name
      }
    end
  end

  def create_data_elements_for_state(package_des, state_label)
    state_created_des = []
    package_des.each do |de|
      de_to_create = [{
        code:         "#{state_label.underscore.capitalize}-#{de[:id]}"[0..49],
        short_name:   "#{state_label.underscore.capitalize} for #{de[:name]}"[0..49],
        name:         "#{state_label.underscore.capitalize} for #{de[:name]}",
        display_name: "#{state_label.underscore.capitalize} for #{de[:name]}"
      }]
      dhis2 = incentive.project.dhis2_connection
      dhis2.data_elements.create(de_to_create)
      # query the created indic by name or by code if you want
      state_created_de = dhis2.data_elements.find_by(name: "#{state_label.underscore.capitalize} for #{de[:name]}")
      state_created_des.push state_created_de
    end
    # return the ids of the created DEs
    state_created_des
  end

  def create_data_element_group_for_incentive(state_created_des, incentive)
    deg_name = "#{incentive.state.name.underscore.capitalize}-#{incentive.package.name}"
    deg = [
      { name:          deg_name,
        short_name:    deg_name[0..49],
        code:          deg_name[0..49],
        display_name:  deg_name,
        data_elements: state_created_des.map do |state_created_de|
          { id: state_created_de.id }
        end }
    ]
    dhis2 = incentive.project.dhis2_connection
    dhis2.data_element_groups.create(deg)
    dhis2.data_element_groups.find_by(name: deg_name)
  end
end
