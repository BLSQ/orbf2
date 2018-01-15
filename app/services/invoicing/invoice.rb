module Invoicing
  class Invoice < Struct.new(:date, :entity, :project, :activity_results, :package_results, :payment_result)

    attr_reader :lines

    def dump_invoice(debug = false)
      return unless debug
      log "-------********* #{entity.name} #{date}************------------"
      if activity_results
        activity_results.group_by(&:package).map do |package, results|
          log "************ Package #{package.name} "
          log package.invoice_details.join("\t")
          results.each do |result|
            line = package.invoice_details.map { |item| d_to_s(result.solution[item]) }
            log line.join("\t\t")
          end
          next unless package_results
          package_line = package.package_rule.formulas.map(&:code).map do |item|
            package_result = package_results.find { |pr| pr.package == package }
            next unless package_result.solution[item]
            [item, d_to_s(package_result.solution[item])].join("=")
          end
          log package_line.compact.join("\n").to_s
        end
      end

      if payment_result
        package_line = project.payment_rules.first.rule.formulas.map do |formula|
          [formula.code, d_to_s(payment_result.solution[formula.code])].join(" : ")
        end
        log "************ payments "
        log package_line.join("\n")
      end
    end

    def inspect
      to_s
    end

    def to_s
      "Invoice-#{date}-#{package_results&.first&.package&.name}"
    end

    def d_to_s(decimal)
      return format("%.2f", decimal) if decimal.is_a? Numeric
      decimal
    end

    def log(message = "")
      @lines ||= []
      @lines << message
    end

    delegate :to_json, to: :to_h
  end
end
