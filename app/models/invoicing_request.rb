# frozen_string_literal: true

class InvoicingRequest
  include ActiveModel::Model
  include ActiveModel::Validations

  attr_accessor :entity, :year, :quarter, :project, :invoices, :mock_values, :engine_version, :with_details, :mocked_data

  validates :entity, presence: true

  def initialize(*)
    super
    @mocked_data ||= [] if mock_values?
    @mocked_data&.each { |v| v["origin"] ||= "dataValueSets" }
  end

  def start_date_as_date
    year_quarter.start_date
  end

  def end_date_as_date
    year_quarter.end_date
  end

  def year_quarter
    Periods::YearQuarter.new("#{year}Q#{quarter}")
  end

  def period
    year_quarter.to_s
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

  def to_h
    {
      entity:         entity,
      period:         period,
      project_id:     project&.id,
      with_details:   with_details,
      engine_version: engine_version,
      mocked_data:    mocked_data
    }
  end
end
