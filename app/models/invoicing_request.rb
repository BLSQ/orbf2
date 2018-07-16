class InvoicingRequest
  include ActiveModel::Model
  attr_accessor :entity, :year, :quarter, :project, :invoices, :mock_values, :engine_version, :with_details

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

  def engine_version
    Integer(@engine_version)
  end

  def legacy_engine?
    engine_version == 1
  end

  def mock_values?
    mock_values == "1"
  end

  def with_details?
    with_details == "1"
  end
end
