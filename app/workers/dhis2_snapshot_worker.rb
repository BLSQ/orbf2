# frozen_string_literal: true

class Dhis2SnapshotWorker
  include Sidekiq::Worker
  include Sidekiq::Throttled::Worker
  sidekiq_options retry: 5

  PAGE_SIZE = 5000

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
    log_progress("Compacted", kind, start)
    snapshot.disable_tracking = @disable_tracking
    snapshot.save!
    log_progress("Processed", kind, start)
    Rails.logger.info "Dhis2SnapshotWorker #{kind} : for project anchor #{new_snapshot ? 'created' : 'updated'} #{year} #{month} : #{project.project_anchor.id} #{project.name} #{data.size} done!"
    snapshot
  end

  def log_progress(message, kind, start)
    puts "#{Time.new} \t#{message} #{kind} total time : #{Time.new - start})"
  end

  ORGANISATION_UNITS_FIELDS = [
    ":all",
    "!coordinates", "!ancestors", "!access", "!attributeValues", "!users",
    "!dataSets", "!userGroupAccesses", "!dimensionItemType", "!externalAccess"
  ].join(",")

  def fetch_data(project, kind)
    fetcher(project, kind).fetch_data(project, kind)
  end

  def fetcher(project, kind)
    if kind == :organisation_units && project&.entity_group&.limit_snaphot_to_active_regions
      Fetchers::OrganisationUnitsSnapshotFetcher.new(fields: ORGANISATION_UNITS_FIELDS)
    elsif kind == :category_combos
      Fetchers::GenericSnapshotFetcher.new(fields: "id,name,code,categoryOptionCombos[id,name,code]")
    else
      Fetchers::GenericSnapshotFetcher.new
    end
  end
end
