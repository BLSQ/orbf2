# frozen_string_literal: true

class SynchroniseGroupsWorker
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

    return unless project.entity_group.program_reference.presence

    unless project.entity_group.group_synchronisation_enabled
      puts "SynchroniseGroupsWorker skipped : #{project.id} - #{project.name} group_synchronisation_enabled is not enabled"
      return
    end

    # project :
    #   contract_delay_in_months int
    #   group_synchronisation_enabled true

    contract_service = Orbf::RulesEngine::ContractService.new(
      program_id:            project.entity_group.program_reference,
      all_event_sql_view_id: project.entity_group.all_event_sql_view_reference,
      dhis2_connection:      project.dhis2_connection,
      calendar:              project.calendar
    )
    quarterly_period = current_period(now, project)
    contract_service.synchronise_groups(quarterly_period)
  end

  def current_period(now, project)
    calendar = project.calendar
    delay_in_months = project.entity_group.contract_delay_in_months
    delayed_date = now - delay_in_months.months
    date_in_project_calendar = calendar.from_iso(delayed_date.to_datetime)

    monthly_period = Periods.from_dhis2_period(date_in_project_calendar.strftime("%Y%m"))
    quarterly_period = monthly_period.to_quarter.to_dhis2
    puts ["groups synchronisation WITH delayed_date:#{delayed_date}",
          "date_in_project_calendar:#{date_in_project_calendar}",
          "monthly_period:#{monthly_period}",
          "quarterly_period:#{quarterly_period}"].join("\t")

    quarterly_period
  end
end
