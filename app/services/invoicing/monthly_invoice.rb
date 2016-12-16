module Invoicing
  class MonthlyInvoice < Struct.new(:date, :entity, :project, :activity_results, :package_results, :payments)
    def dump_invoice
      puts "-------********* #{entity.name} #{date}************------------"
      if activity_results
        activity_results.flatten.group_by(&:package).map do |package, results|
          puts "************ Package #{package.name} "
          puts package.invoice_details.join("\t")
          results.each do |result|
            line = package.invoice_details.map { |item| d_to_s(result.solution[item]) }
            # line << result.solution.to_json
            puts line.join("\t\t")
          end
          next unless package_results
          package_line = package.invoice_details.map do |item|
            package_result = package_results.find { |pr| pr.package == package }
            d_to_s(package_result.solution[item])
          end
          puts "Totals :  #{package_line.join("\t")}"
        end
      end

      if payments && !payments.empty?
        package_line = project.payment_rule.formulas.map do |formula|
          [formula.code, d_to_s(payments[formula.code])].join(" : ")
        end
        puts "************ payments "
        puts package_line.join("\n")
      end
      puts
    end

    def d_to_s(decimal)
      return "%.2f" % decimal if decimal.is_a? Numeric
      decimal
    end
  end
end
