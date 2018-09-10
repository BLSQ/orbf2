# frozen_string_literal: true

class Dhis2SnapshotWorker
  include Sidekiq::Worker
  include Sidekiq::Throttled::Worker
  PAGE_SIZE = 5000
  sidekiq_options retry: 5

  sidekiq_throttle(
    concurrency: { limit: 1 },
    threshold:   { limit: 3, period: 2.minutes }
  )

  def perform(project_anchor_id, filter: nil, now: Time.now.utc, disable_tracking: true)
    @disable_tracking = disable_tracking
    project_anchor = ProjectAnchor.find(project_anchor_id)

    project = project_anchor.projects.for_date(now) || project_anchor.latest_draft

    Dhis2Snapshot::KINDS.each do |kind|
      next if filter && !filter.include?(kind.to_s)
      snapshot(project, kind, now)
    end
  end

  def snapshot(project, kind, now)
    data = fetch_data(project, kind)
    dhis2_version = project.dhis2_connection.system_infos.get["version"]
    snapshot = nil
    project.project_anchor.with_lock do
      snapshot = compact_and_store(project, kind, now, data, dhis2_version)
    end
    snapshot
  end

  def compact_and_store(project, kind, now, data, dhis2_version)
    month = now.month
    year = now.year
    new_snapshot = false
    snapshot = project.project_anchor.dhis2_snapshots.find_or_initialize_by(
      kind:  kind,
      month: month,
      year:  year
    ) do
      new_snapshot = true
    end
    start = Time.new
    snapshot.content = JSON.parse(data.to_json)
    snapshot.job_id = jid || "railsc"
    snapshot.dhis2_version = dhis2_version
    Dhis2SnapshotCompactor.new.compact(snapshot)
    puts "#{Time.new} \tCompacted #{kind} total time : #{Time.new - start})"
    snapshot.disable_tracking = @disable_tracking
    snapshot.save!
    puts "#{Time.new} \tProcessed #{kind} : #{Time.new - start})"
    Rails.logger.info "Dhis2SnapshotWorker #{kind} : for project anchor #{new_snapshot ? 'created' : 'updated'} #{year} #{month} : #{project.project_anchor.id} #{project.name} #{data.size} done!"
    snapshot
  end

  def fetch_data(project, kind)
    data = []
    begin
      start = Time.new
      dhis2 = project.dhis2_connection
      paged_data = dhis2.send(kind).list(fields: ":all", page_size: PAGE_SIZE)
      data.push(*paged_data)
      page_count = paged_data.pager.page_count
      puts "#{Time.new} \t Processed page 1 of #{page_count} (Size: #{paged_data.size}, total time : #{Time.new - start})"
      if page_count > 1
        (2..page_count).each do |page|
          paged_data = dhis2.send(kind).list(fields: ":all", page_size: PAGE_SIZE, page: page)
          data.push(*paged_data)
          puts "#{Time.new} \t Processed page #{page} of #{page_count} (Size: #{paged_data.size}, total time : #{Time.new - start})"
        end
      end
    rescue RestClient::Exception => e
      Rails.logger.info "#{kind} #{e.message}"
      raise "#{kind} #{e.message}"
    end
    data
  end
end
