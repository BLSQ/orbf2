module Publishing
  class Dhis2InvoicePublisher
    def publish(project, invoices)
      values = to_values(invoices)
      Rails.logger.info "about to publish #{values.size} values to dhis2"
      return if values.empty?
      status = project.dhis2_connection.data_value_sets.create(values)
      Rails.logger.info values.to_json
      Rails.logger.info status.raw_status.to_json
      project.project_anchor.dhis2_logs.create(sent: values, status: status.raw_status)
      status
    end

    private

    def to_values(invoices)
      (activity_values(invoices) + package_values(invoices) + payment_values(invoices)).compact
    end

    def payment_values(invoices)
      invoices.select(&:payment_result).each_with_object([]) do |invoice, array|
        period = Periods.year_month(invoice.date)
        invoice.payment_result.payment_rule.rule.formulas.select(&:formula_mapping).each do |formula|
          mapping = formula.formula_mapping
          array.push({
            dataElement: mapping.external_reference,
            orgUnit:     invoice.entity.id,
            period:      format_to_dhis_period(
              period,
              formula.frequency || invoice.payment_result.payment_rule.frequency
            ),
            value:       invoice.payment_result.solution[formula.code],
            comment:     "$-#{formula.code}-#{invoice.payment_result.payment_rule.rule.name}"
          })
        end
      end
    end

    def package_values(invoices)
      invoices.each_with_object([]) do |invoice, array|
        period = Periods.year_month(invoice.date)
        invoice.package_results.each do |package_result|
          package_result.package.package_rule.formulas.select(&:formula_mapping).each do |formula|
            mapping = formula.formula_mapping
            next if !package_result.frequency.nil? && package_result.frequency != package_result.package.frequency

            array.push({
              dataElement: mapping.external_reference,
              orgUnit:     invoice.entity.id,
              period:      format_to_dhis_period(
                period,
                formula.frequency || package_result.package.frequency
              ),
              value:       package_result.solution[formula.code],
              comment:     "P-#{formula.code}-#{package_result.package.name}"
            })
          end
        end
      end
    end

    def activity_values(invoices)
      invoices.each_with_object([]) do |invoice, array|
        period = Periods.year_month(invoice.date)
        invoice.activity_results.each do |activity_result|
          activity = activity_result.activity
          package = activity_result.package
          package.activity_rule.formulas.select { |f| f.formula_mapping(activity) }.each do |formula|
            mapping = formula.formula_mapping(activity)
            array.push({
              dataElement: mapping.external_reference,
              orgUnit:     invoice.entity.id,
              period:      format_to_dhis_period(
                period,
                formula.frequency || package.frequency
              ),
              value:       activity_result.solution[formula.code],
              comment:     "A-#{formula.code}-#{activity.name}"
            })
          end
        end
      end
    end

    def format_to_dhis_period(year_month, frequency)
      period = year_month
      period = period.to_year if frequency == "yearly"
      period = period.to_quarter if frequency == "quarterly"
      period.to_dhis2
    end
  end
end
