class Groups::UpdateParams
  include Groups::Params

  attr_reader :reference_period, :project, :project_anchor,
              :selected_orgunit_ids, :compared_months,
              :groupset_id, :reference_period_data, :whodunnit

  def initialize(project_anchor, params)
    @project_anchor = project_anchor
    @project = project_anchor.project

    periods = params.fetch(:periods).map do |period|
      Periods.from_dhis2_period(period)
    end
    compared_months = periods.sort
    @reference_period_data = params.fetch(:referencePeriod)
    ref = reference_period_data.fetch(:period).fetch(:dhis2)
    @reference_period = Periods.from_dhis2_period(ref)
    @compared_months = compared_months - [reference_period]
    @selected_orgunit_ids = [reference_period_data.fetch(:id)]
    @whodunnit = params.fetch(:dhis2UserId)

    @groupset_id = project.packages.map(&:ogs_reference).compact.first
    ensure_whodunnit
    ensure_not_current_or_futur
  end

  def ensure_not_current_or_futur
    raise ArgumentError.new("at least one period") unless compared_months && compared_months.size >= 1
    now = Periods.year_month(DateTime.now.to_date)
    raise ArgumentError.new("periods are in current or futur #{compared_months.map(&:to_dhis2).join(",")}") if compared_months.any? { |period| period >= now }
  end
end
