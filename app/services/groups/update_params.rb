class Groups::UpdateParams
  attr_reader :periods, :reference_period, :project, :project_anchor,
              :selected_orgunit_ids, :compared_months,
              :groupset_id, :reference_period_data
  def initialize(project_anchor, params)
    @project_anchor = project_anchor
    @project = project_anchor.project

    periods = params.fetch(:periods).map do |period|
      Periods.from_dhis2_period(period)
    end
    compared_months = periods.sort
    @reference_period_data = params.fetch(:reference_period)
    ref = reference_period_data.fetch(:period).fetch(:dhis2)
    @reference_period = Periods.from_dhis2_period(ref)
    @compared_months = compared_months - [reference_period]
    @selected_orgunit_ids = [reference_period_data.fetch(:id)]

    @groupset_id = project.packages.map(&:ogs_reference).compact.first
  end
end
