class Groups::GroupParams
  attr_reader :periods, :reference_period, :project,
              :selected_orgunit_ids, :compared_months,
              :excluded_orgunit_ids, :groupset_id
  def initialize(project_anchor, params)
    @project = project_anchor.project
    quarter_periods = params.fetch(:periods).split(",").map do |period|
      Periods.from_dhis2_period(period)
    end
    compared_months = quarter_periods.flat_map(&:months).sort
    @reference_period = Periods.from_dhis2_period(params.fetch(:reference_period))
    @compared_months = compared_months - [reference_period]
    @selected_orgunit_ids = params.fetch("organisationUnits").split(",")
    @excluded_orgunit_ids = %w[]

    @groupset_id = project.packages.map(&:ogs_reference).compact.first
  end
end
