class Dhis2SnapshotWorker
  include Sidekiq::Worker

  def perform(project_anchor_id, type)
    puts "Dhis2SnapshotWorker for project anchor #{project_anchor_id} #{type} done!"
  end
end
