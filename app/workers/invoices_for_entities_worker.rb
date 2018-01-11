
class InvoicesForEntitiesWorker
  include Sidekiq::Worker

  def perform(project_anchor_id, year, quarter, org_unit_ids, options = {})
    ::Invoicing::CreateForEntities.new(project_anchor_id, year, quarter, org_unit_ids, options).call
  end
end
