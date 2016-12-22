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

    if @incentive.valid?
      if @incentive.activity_incentives
        # save values and redirect_to setup... with a log of IncentiveConfigs

        groups = params[:incentive_config][:entity_groups].map(&:to_s).join(",")
        data_elements = params[:incentive_config][:activity_incentives]

        dhis2 = incentive.project.dhis2_connection

        # get orgUnits of these groups
        # https://play.dhis2.org/demo/api/organisationUnits.json?filter=organisationUnitGroups.id:in:[RXL3lPSK8oG]
        org_units = dhis2.organisation_units.list(filter: "organisationUnitGroups.id:in:[#{groups}]")
        # loop and set values for each

        period = params[:incentive_config][:start_date].split("-")
        period.pop
        period = period.map(&:to_s).join("")

        values = []
        org_units.each do |org_unit|
          data_elements.each do |data_element|
            de_values = {
              value:        data_elements[data_element][:value],
              period:       period,
              org_unit:     org_unit.id,
              data_element: data_elements[data_element][:external_reference]
            }
            values.push de_values
          end
        end
        status = dhis2.data_value_sets.create(values)
        if status.raw_status["status"] == "SUCCESS"
          ttl_affected = status.raw_status["import_count"]["imported"] + status.raw_status["import_count"]["updated"]
          flash[:success] = "#{@incentive.state.name}-#{@incentive.package.name} created successfuly for #{ttl_affected} Org. Units"
          redirect_to(root_path)
        end

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
                  entity_groups:       [],
                  activity_incentives: [:value, :name, :external_reference])
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
