class InvoicingRequest
  include ActiveModel::Model
  attr_accessor :entity, :year, :quarter, :project, :invoices, :mock_values, :legacy_engine

  def start_date_as_date
    year_quarter.start_date
  end

  def end_date_as_date
    year_quarter.end_date
  end

  def year_quarter
    Periods::YearQuarter.new("#{year}Q#{quarter}")
  end

  def invoices
    @invoices ||= []
  end

  def quarter_dates
    year_quarter.months.map(&:end_date)
  end

  def legacy_engine?
    legacy_engine=="1" || legacy_engine=="true"
  end
end