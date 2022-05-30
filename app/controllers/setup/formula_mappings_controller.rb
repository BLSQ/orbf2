# frozen_string_literal: true

class Setup::FormulaMappingsController < PrivateController
  attr_reader :formula_mappings
  helper_method :formula_mappings

  def new
    check_problems
    @formula_mappings = build_formula_mappings(to_options)
  end

  def create
    check_problems

    @formula_mappings = build_formula_mappings(to_options)

    @formula_mappings.mappings.each do |mapping|
      mapping.save! if mapping.valid?
      mapping.destroy! if mapping.external_reference.blank? && mapping.id
    end
    @formula_mappings.mappings = @formula_mappings.mappings.reject(&:destroyed?)

    OutputDatasetWorker.trigger_sync_for_project(current_project)

    render :new
  end

  def create_data_element
    activity = current_project.activities.find(params[:activity_id]) if params[:activity_id]
    formula = Formula.find(params[:formula_id])
    raise "invalid formula id" if formula.project_id != current_project.id

    CreateDhis2ElementForFormulaMappingWorker.perform_async(
      current_project.id,
      "activity_id"  => activity&.id,
      "formula_id"   => formula.id,
      "kind"         => params[:kind],
      "data_element" => {
        "name"       => params[:name],
        "short_name" => params[:short_name],
        "code"       => params[:code]
      }
    )
    render partial: "create_data_element"
  end

  private

  def check_problems
    project = current_project(project_scope: :fully_loaded)
    in_references = project.activities.flat_map(&:activity_states).map(&:external_reference)
    out_references = project.formula_mappings.map(&:external_reference)

    bad_references = in_references & out_references

    @problems = bad_references.map do |bad_reference|
      as = project.activities.flat_map(&:activity_states).select { |as| as.external_reference == bad_reference }.first
      fm = project.formula_mappings.select { |fm| fm.external_reference == bad_reference }.first
      [bad_reference, "MAPPED IN AND OUT", as.activity.name, as.state.name, fm.formula.code, fm.activity&.name]
    end

    @problems += project.formula_mappings.group_by(&:external_reference).select { |_k, v| v.size > 1 }.map do |k, v|
      [k, "MAPPED OUT MULTIPLE TIMES", v.map { |fm| [fm.kind, fm.activity&.name, fm.formula.code] }].flatten
    end

    @to_check = @problems.map(&:first)
  end

  def to_options
    mode_options = {
      missing_only: { missing_only: true },
      activity_only: { package: false, payment: false, zone: false },
      package_only: { activity: false, payment: false, zone: false },
      payment_only: { package: false, activity: false, zone: false },
      all: {},
      create: { missing_only: true },
      nil => { missing_only: true }
    }
    mode_options[params[:mode] ? params[:mode].to_sym : nil]
  end

  def build_formula_mappings(options = {})
    default_options = { activity: true, package: true, payment: true, zone: true, missing_only: false }
    options = default_options.merge(options)
    mappings = []
    project = current_project(project_scope: :fully_loaded)
    mapping_by_key = params[:formula_mappings] ? params[:formula_mappings].index_by { |mapping| [mapping[:formula_id].to_i, mapping[:activity_id].to_i] } : {}

    if options[:activity]
      activity_rules = project.packages.flat_map(&:rules).select(&:activity_related_kind?)

      mappings += activity_rules.map do |rule|
        rule.package
            .activities
            .select { |a| params[:activity_code].presence ? a.code == params[:activity_code] : true }
            .map do |activity|
          rule.formulas.map do |formula|
            mapping = formula.find_or_build_mapping(
              activity: activity,
              kind:     rule.kind
            )
            mapping = missing?(options, mapping)
            if mapping
              mapping.external_reference = external_reference(mapping_by_key[[formula.id, activity.id]]) unless mapping_by_key.empty?
            end
            mapping
          end
        end
      end
    end

    other_rules = []
    unless params[:activity_code].presence
      other_rules += project.packages.flat_map(&:rules).select(&:package_kind?) if options[:package]
      other_rules += project.packages.flat_map(&:rules).select(&:zone_kind?) if options[:zone]
      other_rules += project.payment_rules.flat_map(&:rule) if options[:payment]
    end

    mappings += other_rules.map do |rule|
      rule.formulas.map do |formula|
        mapping = formula.find_or_build_mapping(
          kind: rule.kind
        )
        mapping = missing?(options, mapping)
        if mapping
          mapping.external_reference = external_reference(mapping_by_key[[formula.id, 0]]) unless mapping_by_key.empty?
        end
        mapping
      end
    end
    if params[:formula_code].presence
      mappings = mappings.flatten.compact.select { |mapping| mapping.formula.code == params[:formula_code] }
    end

    FormulaMappings.new(mappings: mappings.flatten.compact, project: project, mode: params[:mode])
  end

  def missing?(options, mapping)
    return mapping if @to_check.include?(mapping.external_reference)

    options[:missing_only] && mapping.id ? nil : mapping
  end

  def external_reference(param)
    param ? param[:external_reference] : nil
  end
end
