module Groups
  class UpdateParams
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

      @groupset_id = project.packages.map(&:ogs_reference).compact.first
      ensure_whodunnit(params)
      ensure_not_current_or_futur
    end

    def ensure_not_current_or_futur
      at_least_one_period = compared_months && compared_months.size >= 1
      raise ArgumentError, "at least one period" unless at_least_one_period
      now = Periods.year_month(DateTime.now.to_date)
      periods_in_futur = compared_months.any? { |period| period >= now }
      raise ArgumentError, period_in_futur_message if periods_in_futur
    end

    def period_in_futur_message
      "periods are in current or futur #{compared_months.map(&:to_dhis2).join(',')}"
    end
  end
end
