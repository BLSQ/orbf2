# frozen_string_literal: true

class Setup::InvoicesController < PrivateController
  attr_reader :invoicing_request, :indexed_project
  helper_method :invoicing_request
  helper_method :indexed_project

  def new
    project = current_project(project_scope: :fully_loaded) if params["calculate"]
    @invoicing_request = InvoicingRequest.new(
      project:        current_project,
      year:           params[:year] || Date.today.to_date.year,
      quarter:        params[:quarter] || (Date.today.to_date.month / 4) + 1,
      entity:         params[:entity],
      with_details:   params[:with_details] || false,
      engine_version: 3 # TODO: current_project.engine_version
    )
    if params["calculate"]
      render_invoice(project, invoicing_request)
      return
    end
  end

  def create
    project = current_project(project_scope: :fully_loaded)

    @invoicing_request = InvoicingRequest.new(invoice_params.merge(project: project))
    @org_unit_limiter = OrgUnitLimiter.from_params(params)

    if @invoicing_request.valid?
      render_invoice(project, invoicing_request)
    else
      render :new
    end
  end

  class OrgUnitLimiter
    # Small PORO to help with the `selected_org_units` filter, a user
    # can selectively choose to limit the results to certain org
    # units.
    def self.from_params(incoming)
      org_unit_ids = (incoming[:selected_org_units] || "").split(",").map(&:strip)
      new(org_unit_ids)
    end

    def active?
      org_unit_ids.count > 0
    end

    def initialize(selected_org_units)
      @selected_org_units = selected_org_units
    end

    def has_org_unit?(org_unit_id)
      org_unit_ids.include?(org_unit_id)
    end

    def org_unit_ids
      @selected_org_units || []
    end

    def to_param
      return {} unless active?

      { selected_org_units: org_unit_ids.join(",") }
    end
  end

  private

  def render_invoice(project, invoicing_request)
    if params[:push_to_dhis2] && invoicing_request.entity
      InvoiceForProjectAnchorWorker.perform_async(
        project.project_anchor_id,
        invoicing_request.year,
        invoicing_request.quarter,
        [invoicing_request.entity]
      )
      flash[:alert] = "Worker scheduled for #{invoicing_request.entity} : #{invoicing_request.year_quarter.to_dhis2}"
      render(:new)
      return
    end

    if invoicing_request.legacy_engine?
      render_legacy_invoice(project, invoicing_request)
    else
      render_new_invoice(project, invoicing_request)
    end
  end

  def render_new_invoice(project, invoicing_request)
    options = Invoicing::InvoicingOptions.new(
      publish_to_dhis2:       false,
      force_project_id:       params[:simulate_draft] ? project.id : nil,
      allow_fresh_dhis2_data: params[:simulate_draft]
    )

    @invoice_entity = Invoicing::InvoiceEntity.new(project.project_anchor, invoicing_request, options)
    @invoice_entity.call
    @indexed_project = Invoicing::IndexedProject.new(project, @invoice_entity.orbf_project)
    Invoicing::MapToInvoices.new(invoicing_request, @invoice_entity.fetch_and_solve.solver).call

    @dhis2_export_values = @invoice_entity.fetch_and_solve.exported_values
    @dhis2_input_values = @invoice_entity.fetch_and_solve.dhis2_values
    @pyramid = @invoice_entity.pyramid
    @data_compound = @invoice_entity.data_compound

    @org_unit_summaries = Invoicing::EntitySignalitic.new(
      @pyramid,
      invoicing_request.entity
    ).call

    add_contract_warning_if_non_contracted(invoicing_request, project)

    if false #params[:json]
      render_json(invoicing_request, project)
    else
      render "new_invoice"
    end
  rescue StandardError => e
    @exception = e
    puts "An error occured during simulation #{e.class.name} #{e.message}" + e.backtrace.join("\n")
    flash[:failure] = "An error occured during simulation #{e.class.name} #{e.message[0..100]}"
    render "new_invoice"
  end

  def render_legacy_invoice(project, invoicing_request)
    pyramid = project.project_anchor.nearest_pyramid_for(invoicing_request.end_date_as_date)
    pyramid ||= Pyramid.from(project)
    @pyramid = pyramid

    @datacompound = project.project_anchor.nearest_data_compound_for(invoicing_request.end_date_as_date)
    @datacompound ||= DataCompound.from(project)

    org_unit = pyramid.org_unit(invoicing_request.entity)
    @org_unit = org_unit

    render(:new) && return unless org_unit
    org_unit.pyramid ||= pyramid

    @org_unit_summaries = [
      org_unit.name,
      "parents : " + pyramid.org_unit_parents(org_unit.id).map(&:name).join(" > "),
      "groups : " + pyramid.org_unit_groups_of(org_unit).compact.map(&:name).join(", "),
      "date range : " + project.date_range(invoicing_request.year_quarter).map(&:to_s).join(", "),
      "periods : " + project.periods(invoicing_request.year_quarter).map(&:to_dhis2).join(", "),
      "facts : " + Invoicing::EntityBuilder.new.to_entity(org_unit).facts.map(&:to_s).join(", ")
    ]

    unless pyramid.belong_to_group(org_unit, project.entity_group.external_reference)
      flash[:failure] = "Warn this entity is not in the contracted entity group : #{project.entity_group.name}."
      flash[:failure] += "Only simulation will work. Update the group and trigger a dhis2 snaphots."
    end

    options = {
      publisher_ids: [],
      mock_values:   invoicing_request.mock_values?
    }

    if params[:simulate_draft]
      options = options.merge(
        force_project_id:       project.id,
        allow_fresh_dhis2_data: true
      )
    end

    begin
      invoicing_request.invoices = InvoicesForEntitiesWorker.new.perform(
        project.project_anchor_id,
        invoicing_request.year,
        invoicing_request.quarter,
        [org_unit.id],
        options
      )[org_unit.id]

      invoicing_request.invoices = invoicing_request.invoices.sort_by(&:date)
    rescue Rules::SolvingError => e
      @exception = e
      log(e)
      flash[:alert] = "Failed to simulate invoice : #{e.class.name} #{e.message[0..100]} : <br>#{e.facts_and_rules.map { |k, v| [k, v].join(' : ') }.join(' <br>')}".html_safe
    rescue StandardError => e
      @exception = e
      log(e)
      flash[:alert] = "Failed to simulate invoice : #{e.class.name} #{e.message[0..100]}"
    end
    render :new
  end

  def log(exception)
    Rails.logger.info " #{exception.message} : \n#{exception.backtrace.join("\n")}"
  end

  def invoice_params
    params.require(:invoicing_request)
          .permit(:entity,
                  :year,
                  :quarter,
                  :mock_values,
                  :engine_version,
                  :with_details)
  end

  def add_contract_warning_if_non_contracted(invoicing_request, project)
    return if contracted?(invoicing_request, project)

    flash[:failure] = non_contracted_orgunit_message(project)
  end

  def contracted?(invoicing_request, project)
    org_unit = @pyramid.org_unit(invoicing_request.entity)
    org_unit.group_ext_ids.include?(project.entity_group.external_reference)
  end

  def non_contracted_orgunit_message(project)
    "Entity is not in the contracted entity group : #{project.entity_group.name}." \
     " (Snaphots last updated on #{project.project_anchor.updated_at.to_date})." \
     " Only simulation will work. Update the group and trigger a dhis2 snaphots." \
     " Note that it will only fix this issue for current or futur periods."
  end

  def render_json(invoicing_request, project)
  def invoice_output_input_act_class(activity_item, code)
    begin
      activity_item.input?(code)
    rescue StandardError
      return ""
    end
    if activity_item.input?(code)
      "formula-input"
    elsif activity_item.output?(code)
      "formula-output"
    end
  end
  is_input = -> (activity_item, code) {
    begin
      activity_item.input?(code)
    rescue StandardError
      false
    end
  }
  is_output = -> (activity_item, code) {
    begin
      activity_item.output?(code)
    rescue StandardError
      false
    end
  }
    render json: JSON.pretty_generate(
      request:             {
        entity:            invoicing_request.entity,
        period:            invoicing_request.year_quarter.to_dhis2,
        engine_version:    invoicing_request.engine_version,
        organisation_unit: Invoicing::EntitySignalitic.new(
          @invoice_entity.pyramid,
          invoicing_request.entity
        ).to_h,
        warnings:          contracted?(invoicing_request, project) ? nil : non_contracted_orgunit_message(project)
      },
      invoices:            invoicing_request.invoices.map do |invoice|
                             {
                               orgunit_ext_id: invoice.orgunit_ext_id,
                               period:         invoice.period,
                               kind:           invoice.kind,
                               code:           invoice.code,
                               activity_items: invoice.activity_items.map do |activity_item|
                                 {
                                   activity: {
                                     code: activity_item.activity.activity_code,
                                     name: activity_item.activity.name
                                   },
                                   cells:    activity_item.variables.each_with_object({}) do |orbf_var, formulas|
                                               key = orbf_var.formula&.code || orbf_var.state
                                               next unless activity_item.solution[key]

                                               activity_state = indexed_project.lookup_activity_state(orbf_var)
                                               cell = {
                                                 key:                     orbf_var.key,
                                                 instantiated_expression: orbf_var.expression,
                                                 not_exported:            activity_item.not_exported?(key),
                                                 solution:                activity_item.solution[key]&.to_s,
                                                 substituted:              activity_item.substitued[key],
                                                 is_input: is_input.call(activity_item, key),
                                                 is_output: is_output.call(activity_item, key)
                                               }
                                               if activity_state
                                                 cell[:state] = {
                                                   ext_id: activity_state.ext_id,
                                                   kind:   activity_state.kind,
                                                   name:   (@data_compound.data_element(activity_state.ext_id) || @data_compound.indicator(activity_state.ext_id))&.name
                                                 }
                                               end
                                               if orbf_var.formula
                                                 cell[:expression] = orbf_var.formula.expression
                                                 cell[:dhis2_data_element] = orbf_var.dhis2_data_element
                                               end
                                               formulas[key] = cell
                                             end
                                 }
                               end,
                               total_items:    invoice.total_items.sort_by {|total_item| total_item.formula.code }.uniq.map do |total_item|
                                 {
                                   formula:                 total_item.formula.code,
                                   not_exported:            total_item.not_exported,
                                   expression:              total_item.explanations[0],
                                   instantiated_expression: total_item.explanations[2],
                                   solution:                total_item.value&.to_s,
                                   substitued:              total_item.explanations[1],
                                   is_output:               total_item.formula.dhis2_mapping,
                                 }
                               end
                             }
                           end,
      dhis2_export_values: @dhis2_export_values,
      dhis2_input_values:  @dhis2_input_values
    )
  end
end
