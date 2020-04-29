# frozen_string_literal: true

module InvoicesHelper
  def invoice_output_input_class(total_item)
    total_item.formula.dhis2_mapping_de ? "formula-output" : nil
  end

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

  def project_descriptor(project)
    Descriptor::ProjectDescriptorFactory.new.project_descriptor(project)
  end

  def as_pretty_json_string(object)
    JSON.pretty_generate(JSON.parse(object.to_json))
  end
end
