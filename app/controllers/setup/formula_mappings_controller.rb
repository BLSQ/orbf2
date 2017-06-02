
class Setup::FormulaMappingsController < PrivateController
  attr_reader :formula_mappings
  helper_method :formula_mappings

  def new
    @formula_mappings = build_formula_mappings(to_options)
  end

  def create
    @formula_mappings = build_formula_mappings(to_options)

    @formula_mappings.mappings.each do |mapping|
      mapping.save! if mapping.valid?
      mapping.destroy! if mapping.external_reference.blank? && mapping.id
    end
    render :new
  end

  private

  def to_options
    mode_options = {
      missing_only: { missing_only: true },
      activity_only: { package: false, payment: false },
      package_only: { activity: false, payment: false },
      payment_only: { package: false, activity: false },
      all: { },
      nil => { missing_only: true }
    }
    mode_options[params[:mode] ? params[:mode].to_sym : nil]
  end

  def build_formula_mappings(options = {})
    default_options = { activity: true, package: true, payment: true, missing_only: false }
    options = default_options.merge(options)
    mappings = []
    project = current_project(project_scope: :fully_loaded)
    mapping_by_key = params[:formula_mappings] ? params[:formula_mappings].index_by { |mapping| [mapping[:formula_id].to_i, mapping[:activity_id].to_i] } : {}
    puts mapping_by_key
    if options[:activity]
      activity_rules = project.packages.flat_map(&:rules).select(&:activity_kind?)

      mappings += activity_rules.map do |rule|
        rule.package.activities.map do |activity|
          rule.formulas.map do |formula|
            mapping = formula.find_or_build_mapping(
              activity: activity,
              kind:     rule.kind
            )
            mapping.external_reference = external_reference(mapping_by_key[[formula.id, activity.id]]) || mapping.external_reference
            options[:missing_only] && mapping.id ? nil : mapping
          end
        end
      end
    end

    other_rules = []
    other_rules += project.packages.flat_map(&:rules).select(&:package_kind?) if options[:package]
    other_rules += project.payment_rules.flat_map(&:rule) if options[:payment]

    mappings += other_rules.map do |rule|
      rule.formulas.map do |formula|
        mapping = formula.find_or_build_mapping(
          kind: rule.kind
        )

        mapping.external_reference = external_reference(mapping_by_key[[formula.id, 0]]) || mapping.external_reference
        options[:missing_only] && mapping.id ? nil : mapping
      end
    end

    FormulaMappings.new(mappings: mappings.flatten.compact, project: project, mode: params[:mode])
  end

  def external_reference(param)
    param ? param[:external_reference] : nil
  end
end
