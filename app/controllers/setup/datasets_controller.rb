class Setup::DatasetsController < PrivateController
  def index
    Datasets::BuildDatasets.new(current_project).call
    Datasets::CalculateDesyncDatasets.new(current_project).call
  end

  def update
    current_dataset = PaymentRuleDataset.find(params[:id])
    raise "unauthorized" unless current_project.payment_rules.include?(current_dataset.payment_rule)

    OutputDatasetWorker.new.perform(
      current_project.id,
      current_dataset.payment_rule.code,
      current_dataset.frequency,
      "modes" => params[:dataset][:sync_methods].reject(&:empty?)
    )
  end

  def create
    payment_rule_code = params.fetch(:payment_rule_code)
    frequency = params.fetch(:frequency)

    OutputDatasetWorker.new.perform(current_project.id, payment_rule_code, frequency, "modes" => ["create"])

    redirect_to setup_project_datasets_path(current_project)
  end
end
