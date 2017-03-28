

class ProjectFactory
  def build(project_props = { dhis2_url: "http://play.dhis2.org/demo", user: "admin", password: "district", bypass_ssl: false })
    project = Project.new({
      name: "LESOTHO"
    }.merge(project_props))

    package_quantity_pma = new_package(
      "Quantity PMA",
      "monthly",
      ["fosa_group_id"],
      [
        Rule.new(
          name:     "Quantity PMA",
          kind:     "activity",
          formulas: [
            new_formula(
              :difference_percentage,
              "if (verified != 0.0, (ABS(claimed - verified) / verified ) * 100.0, 0.0)",
              "Pourcentage difference entre déclaré & vérifié"
            ),
            new_formula(
              :quantity,
              "IF(difference_percentage < 5, verified , 0.0)",
              "Quantity for PBF payment"
            ),
            new_formula(
              :amount,
              "quantity * tarif",
              "Total payment"
            )
          ]
        ),
        Rule.new(
          name:     "Quantity PMA",
          kind:     "package",
          formulas: [
            new_formula(
              :quantity_total_pma,
              "SUM(%{amount_values})",
              "Amount PBF"
            )
          ]
        )
      ],
      %w(claimed verified
         difference_percentage quantity
         tarif amount
         activity_name quantity_total_pma)
    )

    package_quantity_pca = new_package(
      "Quantity PCA",
      "monthly",
      ["hospital_group_id"],
      [
        Rule.new(
          name:     "Quantity PCA",
          kind:     "activity",
          formulas: [
            new_formula(
              :difference_percentage,
              "if (verified != 0.0, (ABS(claimed - verified) / verified ) * 100.0, 0.0)",
              "Pourcentage difference entre déclaré & vérifié"
            ),
            new_formula(
              :quantity,
              "IF(difference_percentage < 5, verified , 0.0)",
              "Quantity for PBF payment"
            ),
            new_formula(
              :amount,
              "quantity * tarif",
              "Total payment"
            )
          ]
        ),
        Rule.new(
          name:     "Quantity PHU",
          kind:     "package",
          formulas: [
            new_formula(
              :quantity_total_pca,
              "SUM(%{amount_values})",
              "Amount PBF"
            )
          ]
        )
      ],
      %w(claimed verified difference_percentage quantity tarif amount activity_name quantity_total_pca)

    )

    package_quality = new_package(
      "Quality",
      "quarterly",
      %w(hospital_group_id fosa_group_id),
      [
        Rule.new(
          name:     "Quality assessment",
          kind:     "activity",
          formulas: [
            new_formula(
              :attributed_points,
              "claimed",
              "Attrib. Points"
            ),
            new_formula(
              :max_points,
              "max_score",
              "Max Points"
            ),
            new_formula(
              :quality_technical_score_value,
              "if (max_points != 0.0, (attributed_points / max_points) * 100.0, 0.0)",
              "Quality score"
            )
          ]
        ),
        Rule.new(
          name:     "QUALITY score",
          kind:     "package",
          formulas: [
            new_formula(
              :attributed_points,
              "SUM(%{attributed_points_values})",
              "Quality score"
            ),
            new_formula(
              :max_points,
              "SUM(%{max_points_values})",
              "Quality score"
            ),
            new_formula(
              :quality_technical_score_value,
              "SAFE_DIV(SUM(%{attributed_points_values}),SUM(%{max_points_values})) * 100.0",
              "Quality score"
            )
          ]
        )
      ],
      %w(attributed_points max_points quality_technical_score_value activity_name)

    )

    package_perfomance_admin = new_package(
      "Performance Adm",
      "quarterly",
      ["administrative_group_id"],
      [
        Rule.new(
          name:     "Performance assessment",
          kind:     "activity",
          formulas: [
            new_formula(
              :attributed_points,
              "claimed",
              "Attrib. Points"
            ),
            new_formula(
              :max_points,
              "max_score",
              "Max Points"
            ),
            new_formula(
              :performance_score_value,
              "if (max_points != 0.0, (attributed_points / max_points) * 100.0, 0.0)",
              "Performance score"
            )
          ]
        ),
        Rule.new(
          name:     "Performance score",
          kind:     "package",
          formulas: [
            new_formula(
              :attributed_points_perf,
              "SUM(%{attributed_points_values})",
              "Attributed points"
            ),
            new_formula(
              :max_points_perf,
              "SUM(%{max_points_values})",
              "Max points"
            ),
            new_formula(
              :performance_score_value,
              "(attributed_points_perf/max_points_perf) * 100.0",
              "Performance score"
            ),
            new_formula(
              :performance_amount,
              "(performance_score_value / 100.0) * budget",
              "Performance amount"
            )
          ]
        )
      ],
      %w(claimed verified
         difference_percentage quantity
         tarif amount
         activity_name quantity_total)
    )

    project.packages = [package_quantity_pma, package_quantity_pca, package_quality, package_perfomance_admin]

    payment_pma = project.payment_rules.build(
      rule_attributes: {
        name:                "Payment rule pma",
        kind:                "payment",
        formulas_attributes: [
          {
            code:        :quality_bonus_percentage_value,
            expression:  "IF(quality_technical_score_value > 50, (0.35 * quality_technical_score_value) + (0.30 * 10.0), 0.0) /*todo replace with survey score*/",
            description: "Quality bonus percentage"
          },
          {
            code:        :quality_bonus_value,
            expression:  "quantity_total_pma * quality_bonus_percentage_value",
            description: "Bonus qualité "
          },
          {
            code:        :quarterly_payment,
            expression:  "quantity_total_pma + quality_bonus_value",
            description: "Quarterly Payment"
          }
        ]
      }
    )
    [package_quantity_pma, package_quality].each do |package|
        payment_pma.package_payment_rules.build(package: package)
        payment_pma.packages << package
    end

    package_quality.package_rule.formulas.each do |formula|
      formula.formula_mappings.build(kind: formula.rule.kind, external_reference:"ext-#{formula.code}")
    end
    #project.payment_rules.first.rule.payment_rule = project.payment_rules.first

    payment_pca = project.payment_rules.build(
      rule_attributes: {
        name:                "Payment rule pca",
        kind:                "payment",
        formulas_attributes: [
          {
            code:        :quality_bonus_percentage_value,
            expression:  "IF(quality_technical_score_value > 50, (0.35 * quality_technical_score_value) + (0.30 * 10.0), 0.0) /*todo replace with survey score*/",
            description: "Quality bonus percentage"
          },
          {
            code:        :quality_bonus_value,
            expression:  "quantity_total_pca * quality_bonus_percentage_value",
            description: "Bonus qualité "
          },
          {
            code:        :quarterly_payment,
            expression:  "quantity_total_pca + quality_bonus_value",
            description: "Quarterly Payment"
          }
        ]
      }
    )
    [package_quantity_pca, package_quality].each do |package|
        payment_pca.package_payment_rules.build(package: package)
        payment_pca.packages << package
    end


    project
  end

  private

  def new_formula(code, expression, description)
    Formula.new(code: code, expression: expression, description: description)
  end

  def new_package(name, frequency, groups, rules, invoice_details)
    p = Package.new(name: name, frequency: frequency, data_element_group_ext_ref: "data_element_group_ext_ref")
    p.package_entity_groups = groups.map { |g| PackageEntityGroup.new(name: g, organisation_unit_group_ext_ref: g) }
    p.rules = rules
    p.invoice_details = invoice_details
    p
  end
end
