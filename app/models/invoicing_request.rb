
class InvoicingRequest
  include ActiveModel::Model
  attr_accessor :entity, :year, :quarter, :project, :invoices, :mock_values

  QUARTER_TO_MONTH = {
    1 => 3,
    2 => 6,
    3 => 9,
    4 => 12
  }.freeze

  def start_date_as_date
    Date.parse("#{year}-#{(QUARTER_TO_MONTH[quarter.to_i]-2)}-01")
  end

  def end_date_as_date
    Date.parse("#{year}-#{QUARTER_TO_MONTH[quarter.to_i]}-01").end_of_month
  end

  def invoices
    @invoices ||= []
  end

  def quarter_dates
    [
      end_date_as_date - 2.months,
      end_date_as_date - 1.month,
      end_date_as_date
    ].map(&:end_of_month)
  end
end
