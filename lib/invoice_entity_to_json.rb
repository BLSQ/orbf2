# frozen_string_literal: true

class InvoiceEntityToJson
  attr_accessor :indexed_project

  def initialize(invoice_entity)
    @invoice_entity = invoice_entity
    @invoicing_request = invoice_entity.invoicing_request
    @project = invoice_entity.project
    @indexed_project = Invoicing::IndexedProject.new(@project, @invoice_entity.orbf_project)
    @data_compound = invoice_entity.data_compound
    @dhis2_export_values = invoice_entity.fetch_and_solve.exported_values
    @dhis2_input_values = invoice_entity.fetch_and_solve.dhis2_values
  end

  def call
    serialized_json
  end

  def serializable_hash
    serializable_hash = {}
    serializable_hash[:request] = request_hash
    serializable_hash[:invoices] = @invoicing_request.invoices.map do |invoice|
      invoice_hash(invoice)
    end
    serializable_hash[:dhis2_export_values] = @dhis2_export_values
    serializable_hash[:dhis2_input_values] = @dhis2_input_values
    serializable_hash
  end
  alias to_hash serializable_hash

  def serialized_json
    ActiveSupport::JSON.encode(serializable_hash)
  end

  def request_hash
    {
      entity:            @invoicing_request.entity,
      period:            @invoicing_request.year_quarter.to_dhis2,
      engine_version:    @invoicing_request.engine_version,
      organisation_unit: Invoicing::EntitySignalitic.new(
        @invoice_entity.pyramid,
        @invoicing_request.entity,
        @invoice_entity.fetch_and_solve.contract_service,
        @invoicing_request.period
      ).to_h,
      warnings:          if @project.contract_settings
                           nil
                         elsif contracted?(@invoicing_request, @project)
                           nil
                         else
                           non_contracted_orgunit_message(@project)
                         end
    }
  end

  def invoice_hash(invoice)
    total_items = invoice.total_items.sort_by { |total_item| total_item.formula.code }.uniq
    {
      orgunit_ext_id: invoice.orgunit_ext_id,
      orgunit_name:   pyramid.org_unit(invoice.orgunit_ext_id)&.name,
      period:         invoice.period,
      kind:           invoice.kind,
      coc_ext_id:     invoice.coc_ext_id,
      code:           invoice.code,
      activity_items: invoice.activity_items.map do |activity_item|
        activity_item_hash(activity_item)
      end,
      total_items:    total_items.map do |total_item|
        total_item_hash(total_item)
      end
    }
  end

  def activity_item_hash(activity_item)
    cells = activity_item.variables.map(&:state).uniq.each_with_object({}) do |code, cells|
      orbf_var = activity_item.variable(code)
      next unless orbf_var

      key = orbf_var.formula&.code || orbf_var.state
      next unless activity_item.solution[key]

      activity_state = indexed_project.lookup_activity_state(orbf_var)
      cell = {
        key:                     orbf_var.key,
        value:                   activity_item.solution[key]&.to_s,
        solution:                activity_item.solution[key]&.to_s,
        instantiated_expression: orbf_var.expression,
        not_exported:            activity_item.not_exported?(key),
        substituted:             activity_item.substitued[key],
        is_input:                is_input(activity_item, key),
        is_output:               is_output(activity_item, key)
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
      cells[key] = cell
    end

    {
      meta: {
        key:   activity_item.activity.activity_code,
        value: activity_item.activity.name
      }
    }.merge(cells)
  end

  def total_item_hash(total_item)
    {
      key:                     total_item.key,
      formula:                 total_item.formula.code,
      not_exported:            total_item.not_exported,
      expression:              total_item.explanations[0],
      instantiated_expression: total_item.explanations[2],
      solution:                total_item.value&.to_s,
      substituted:             total_item.explanations[1],
      is_output:               total_item.formula.dhis2_mapping_de
    }
  end

  def pyramid
    @invoice_entity.pyramid
  end

  def contracted?(invoicing_request, project)
    org_unit = pyramid.org_unit(invoicing_request.entity)
    org_unit.group_ext_ids.include?(project.entity_group.external_reference)
  end

  def non_contracted_orgunit_message(project)
    "Entity is not in the contracted entity group : #{project.entity_group.name}." \
     " (Snaphots last updated on #{project.project_anchor.updated_at.to_date})." \
     " Only simulation will work. Update the group and trigger a dhis2 snaphots." \
     " Note that it will only fix this issue for current or futur periods."
  end

  def is_input(activity_item, code)
    activity_item.input?(code)
  rescue StandardError
    false
  end

  def is_output(activity_item, code)
    activity_item.output?(code)
  rescue StandardError
    false
  end
end
