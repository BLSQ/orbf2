class Groups::UpdateParams
  attr_reader :periods, :reference_period, :project, :project_anchor,
              :selected_orgunit_ids, :compared_months,
              :excluded_orgunit_ids, :groupset_id, :reference_period_data
  def initialize(project_anchor, params)
    @project_anchor = project_anchor
    @project = project_anchor.project
    periods = params.fetch(:periods).split(",").map do |period|
      Periods.from_dhis2_period(period)
    end
    compared_months = periods.sort
    @reference_period_data = params.fetch(:reference_period)
    @reference_period = Periods.from_dhis2_period(reference_period_data.fetch(:period).fetch(:dhis2))
    @compared_months = compared_months - [reference_period]
    @selected_orgunit_ids = [reference_period_data.fetch(:id)]
    @excluded_orgunit_ids = %w[]

    @groupset_id = project.packages.map(&:ogs_reference).compact.first
  end
end
