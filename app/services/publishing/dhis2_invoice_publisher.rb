module Publishing
  class Dhis2InvoicePublisher
    def publish(project, invoices)
      values = to_values(project, invoices)
      puts "about to publish #{values.size} values to dhis2"
      return if values.empty?
      status = project.dhis2_connection.data_value_sets.create(values)
      puts values.to_json
      puts status.raw_status.to_json
      project.project_anchor.dhis2_logs.create(sent: values, status: status.raw_status)
      status
    end

    def to_values(_project, invoices)
      (activity_values(invoices) + package_values(invoices) + payment_values(invoices)).compact
    end

    def payment_values(invoices)
      invoices.select(&:payment_result).map do |invoice|
        period = Periods.year_month(invoice.date)
        invoice.payment_result.payment_rule.rule.formulas.select(&:formula_mapping).map do |formula|
          mapping = formula.formula_mapping
          {
            dataElement: mapping.external_reference,
            orgUnit:     invoice.entity.id,
            period:      format_to_dhis_period(period, formula.frequency || invoice.payment_result.payment_rule.frequency),
            value:       invoice.payment_result.solution[formula.code],
            comment:     "$-#{formula.code}-#{invoice.payment_result.payment_rule.rule.name}"
          }
        end
      end.flatten
    end

    def package_values(invoices)
      invoices.map do |invoice|
        period = Periods.year_month(invoice.date)
        invoice.package_results.map do |package_result|
          package_result.package.package_rule.formulas.select(&:formula_mapping).map do |formula|
            mapping = formula.formula_mapping
            next if !package_result.frequency.nil? && package_result.frequency != package_result.package.frequency

            {
              dataElement: mapping.external_reference,
              orgUnit:     invoice.entity.id,
              period:      format_to_dhis_period(period, formula.frequency || package_result.package.frequency),
              value:       package_result.solution[formula.code],
              comment:     "P-#{formula.code}-#{package_result.package.name}"
            }
          end
        end
      end.flatten
    end

    def activity_values(invoices)
      invoices.map do |invoice|
        period = Periods.year_month(invoice.date)
        invoice.activity_results.map do |activity_results|
          activity_results.map do |activity_result|
            activity = activity_result.activity
            package = activity_result.package
            package.activity_rule.formulas.select { |f| f.formula_mapping(activity) }.map do |formula|
              mapping = formula.formula_mapping(activity)
              {
                dataElement: mapping.external_reference,
                orgUnit:     invoice.entity.id,
                period:      format_to_dhis_period(period, formula.frequency || package.frequency),
                value:       activity_result.solution[formula.code],
                comment:     "A-#{formula.code}-#{activity.name}"
              }
            end
          end
        end
      end.flatten
    end

    def format_to_dhis_period(year_month, frequency)
      period = year_month
      period = period.to_year if frequency == "yearly"
      period = period.to_quarter if frequency == "quarterly"
      period.to_dhis2
    end
  end
end
