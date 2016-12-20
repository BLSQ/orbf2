

class ProjectFactory
  def build(project_props = { dhis2_url: "http://play.dhis2.org/demo", user: "admin", password: "district", bypass_ssl: false })
    project = Project.new({
      name: "LESOTHO"
    }.merge(project_props))

    package_quantity_pma = new_package(
      "Quantité PMA",
      "monthly",
      ["fosa_group_id"],
      [
        Rule.new(
          name:     "Quantité PMA",
          kind:     "activity",
          formulas: [
            new_formula(
              :difference_percentage,
              "if (verified != 0.0, (ABS(declared - verified) / verified ) * 100.0, 0.0)",
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
          name:     "Quantité PMA",
          kind:     "package",
          formulas: [
            new_formula(
              :quantity_total,
              "SUM(%{amount_values})",
              "Amount PBF"
            )
          ]
        )
      ],
      %w(declared verified
         difference_percentage quantity
         tarif amount
         actictity_name quantity_total)
    )

    package_quantity_pca = new_package(
      "Quantité PCA",
      "monthly",
      ["hospital_group_id"],
      [
        Rule.new(
          name:     "Quantité PCA",
          kind:     "activity",
          formulas: [
            new_formula(
              :difference_percentage,
              "if (verified != 0.0, (ABS(declared - verified) / verified ) * 100.0, 0.0)",
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
          name:     "Quantité PHU",
          kind:     "package",
          formulas: [
            new_formula(
              :quantity_total,
              "SUM(%{amount_values})",
              "Amount PBF"
            )
          ]
        )
      ],
      %w(declared verified difference_percentage quantity tarif amount actictity_name quantity_total)

    )

    package_quality = new_package(
      "Qualité",
      "quarterly",
      %w(hospital_group_id fosa_group_id),
      [
        Rule.new(
          name:     "Qualité assessment",
          kind:     "activity",
          formulas: [
            new_formula(
              :attributed_points,
              "declared",
              "Attrib. Points"
            ),
            new_formula(
              :max_points,
              "tarif",
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
              "SUM(%{attributed_points_values})/SUM(%{max_points_values}) * 100.0",
              "Quality score"
            )
          ]
        )
      ],
      %w(attributed_points max_points quality_technical_score_value actictity_name)

    )

    project.packages = [package_quantity_pma, package_quantity_pca, package_quality]

    project.rules = [
      Rule.new(
        name:     "Payment rule",
        kind:     "payment",
        formulas: [
          new_formula(
            :quality_bonus_percentage_value,
            "IF(quality_technical_score_value > 50, (0.35 * quality_technical_score_value) + (0.30 * 10.0), 0.0) /*todo replace with survey score*/",
            "Quality bonus percentage"
          ),
          new_formula(
            :quality_bonus_value,
            "quantity_total * quality_bonus_percentage_value",
            "Bonus qualité "
          ),
          new_formula(
            :quarterly_payment,
            "quantity_total + quality_bonus_value",
            "Quarterly Payment"
          )
        ]
      )
    ]

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
