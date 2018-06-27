class Setup::DatasetsController < PrivateController
  def index
    Datasets::BuildDatasets.new(current_project).call
    Datasets::CalculateDesyncDatasets.new(current_project).call
  end

  def update
    current_dataset = PaymentRuleDataset.find(params[:id])
    ensure_update(current_dataset)
    OutputDatasetWorker.perform_async(
      current_project.id,
      current_dataset.payment_rule.code,
      current_dataset.frequency,
      "modes" => params[:dataset][:sync_methods].reject(&:empty?)
    )
    redirect_to setup_project_datasets_path(current_project), flash: {
      notice: "updating dataset #{current_dataset.payment_rule.code},"\
      " #{current_dataset.frequency}. Refresh in a few seconds"
    }
  end

  def create
    payment_rule_code = params.fetch(:payment_rule_code)
    frequency = params.fetch(:frequency)

    OutputDatasetWorker.perform_async(
      current_project.id,
      payment_rule_code,
      frequency, "modes" => ["create"]
    )

    redirect_to setup_project_datasets_path(current_project), flash: {
      notice: "Creating dataset for #{payment_rule_code}, #{frequency}. Refresh in a few seconds"
    }
  end

  private

  def ensure_update(current_dataset)
    belongs_to_current_project = current_project.payment_rules
                                                .include?(current_dataset.payment_rule)
    raise "unauthorized" unless belongs_to_current_project
  end
end
