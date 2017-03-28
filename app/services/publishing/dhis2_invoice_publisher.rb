module Publishing
  class Dhis2InvoicePublisher
    def publish(project, _invoices)
      project.dhis2_connection.values.create
    end

    def to_values(_project, invoices)
      activity_values(invoices) + package_values(invoices) + payment_values(invoices)
    end

    def payment_values(invoices)
      invoices.select{ |invoice| invoice.payment_result}.map do |invoice|
        invoice.payment_result.payment_rule.rule.formulas.select {|f| f.formula_mapping }.map do |formula|
          mapping = formula.formula_mapping
          {
            dataElement: mapping.external_reference,
            orgUnit:     invoice.entity.id,
            period:      format_to_dhis_period(invoice.date, "quaterly"),
            value:       invoice.payment_result.solution[formula.code],
            comment:     "$-#{formula.code}-#{invoice.payment_result.payment_rule.rule.name}"
          }
        end
      end.flatten
    end

    def package_values(invoices)
      invoices.map do |invoice|
        invoice.package_results.map do |package_result|
          package_result.package.package_rule.formulas.select {|f| f.formula_mapping}.map do |formula|
            mapping = formula.formula_mapping
            {
              dataElement: mapping.external_reference,
              orgUnit:     invoice.entity.id,
              period:      format_to_dhis_period(invoice.date, package_result.package.frequency),
              value:       package_result.solution[formula.code],
              comment:     "P-#{formula.code}-#{package_result.package.name}"
            }
          end
        end
      end.flatten
    end

    def activity_values(invoices)
      invoices.map do |invoice|
        invoice.activity_results.map do |activity_results|
          activity_results.map do |activity_result|
            activity = activity_result.activity
            package = activity_result.package
            package.activity_rule.formulas.select { |f| f.formula_mapping(activity) }.map do |formula|
              mapping = formula.formula_mapping(activity)
              {
                dataElement: mapping.external_reference,
                orgUnit:      invoice.entity.id,
                period:      format_to_dhis_period(activity_result.date, package.frequency),
                value:       activity_result.solution[formula.code],
                comment:     "A-#{formula.code}-#{activity.name}"
              }
            end
          end
        end
      end.flatten
    end

    def format_to_dhis_period(date, frequency)
      "#{date.year}#{format_month_to_dhis2_period(date.month, frequency)}"
    end

    def format_month_to_dhis2_period(month, frequency)
      if frequency == "monthly"
        if month >= 10
          month
        else
          "0#{month}"
        end
      else
        "Q#{month_to_quarter(month)}"
      end
    end

    MONTH_TO_QUARTER = {
      1  => 1,
      2  => 1,
      3  => 1,
      4  => 2,
      5  => 2,
      6  => 2,
      7  => 3,
      8  => 3,
      9  => 3,
      10 => 4,
      11 => 4,
      12 => 4
    }.freeze

    def month_to_quarter(month)
      raise if month.to_i > 12 || month.to_i < 1
      MONTH_TO_QUARTER[month.to_i]
    end

  end
end
