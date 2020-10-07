# frozen_string_literal: true

class SynchroniseDegDsWorker
  include Sidekiq::Worker
  include Sidekiq::Throttled::Worker

  sidekiq_options retry: 1

  sidekiq_throttle(
    concurrency: { limit: 1 },
    key_suffix:  ->(project_anchor_id, _time = Time.now.utc) { project_anchor_id }
  )

  def perform(project_anchor_id, now = Time.now.utc)
    project_anchor = ProjectAnchor.find(project_anchor_id)
    project = project_anchor.latest_draft || project_anchor.projects.for_date(now)

    strategy = project.read_through_deg ? Synchros::V2SynchroDeg.new : Synchros::V1SynchroDeg.new

    project.packages.each do |package|
      strategy.synchronize(package)
    end

    Dhis2SnapshotWorker.perform_async(project_anchor_id)
  end
end
